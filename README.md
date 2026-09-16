# arcane_framework_devtools_extension

A [DevTools extension](https://docs.flutter.dev/tools/devtools/extensions) for
[arcane_framework](https://github.com/hanskokx/arcane_framework) that inspects a
running app's live runtime state — feature flags, authentication, theme,
environment, logging, and registered services — directly from Dart & Flutter
DevTools.

This package is the **Flutter web app that is the extension's source**. It is a
companion to the `arcane_framework` package, which **hosts the pre-built
extension assets** at `arcane_framework/extension/devtools/`. End users get the
extension automatically by depending on `arcane_framework`; they never touch
this package directly.

> Docs status: accurate against `arcane_framework_devtools_extension` 1.0.0 and
> `arcane_framework` 3.0.0-dev.1.

---

## Table of contents

- [arcane\_framework\_devtools\_extension](#arcane_framework_devtools_extension)
  - [Table of contents](#table-of-contents)
  - [What the extension shows](#what-the-extension-shows)
  - [How it works](#how-it-works)
    - [RPC protocol](#rpc-protocol)
    - [Transport note](#transport-note)
  - [Repository layout](#repository-layout)
  - [Prerequisites](#prerequisites)
  - [Getting started](#getting-started)
  - [Development loop](#development-loop)
    - [Analysis and formatting](#analysis-and-formatting)
    - [Tests](#tests)
    - [Simulated DevTools environment](#simulated-devtools-environment)
    - [Running against a real DevTools environment](#running-against-a-real-devtools-environment)
  - [End-to-end validation over the VM service](#end-to-end-validation-over-the-vm-service)
  - [Building the extension](#building-the-extension)
  - [Troubleshooting](#troubleshooting)
  - [Resources](#resources)

---

## What the extension shows

Seven tabs, all fed by the `ArcaneServiceBridge`:

| Tab           | Content                                                                                                                                      |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Overview      | One-glance summary of every subsystem (services, flags, auth, theme, env, recent log count).                                                 |
| Services      | Names of all registered `Arcane.service`/framework services.                                                                                 |
| Feature Flags | Names of the enabled `Enum` feature flags (read-only).                                                                                       |
| Auth          | `AuthenticationStatus`, `isSignedIn`, and the auth interface type; buttons to flip between `authenticated` and `unauthenticated`.            |
| Theme         | Current `ThemeMode`, whether it follows the system, and whether a custom theme is registered; buttons to switch `light` / `dark` / `system`. |
| Environment   | Current environment name and whether debug mode is on; buttons to toggle `debug` / `normal`.                                                 |
| Logs          | Live log stream (buffer-capped at 500 entries), level badges, metadata, and a "download logs" action.                                        |

Design decisions worth knowing:

- **Feature-flag toggles are intentionally absent.** Flag *names* are readable,
  but the framework stores typed `Enum`s; reconstructing toggle semantics from a
  name string would be lossy. The extension is read-only for feature flags.
- All UI uses `package:flutter/material.dart`. It must — the extension renders
  inside DevTools' Flutter-based `MaterialApp`, so `material_ui` widgets would
  hit `No MaterialLocalizations found`. See `TODO.md` for the full `material_ui`
  incompatibility write-up.
- The bridge polls every 2 seconds while connected, so a mutation made in the
  app (or from another tool) shows up within one poll cycle. Mutating buttons
  trigger an immediate re-poll after the call.

---

## How it works

The extension is wrapped in `DevToolsExtension` (from `package:devtools_extensions`),
which initializes the shared globals `serviceManager` and `dtdManager`.
`ArcaneServiceBridge` (`lib/src/common/arcane_bridge.dart`) listens to
`serviceManager.connectedState` and `serviceManager.isolateManager.mainIsolate`.
When an app is connected, it polls the app's VM service.

On the app side, `arcane_framework` **registers one service extension
automatically** — no app code required. `ArcaneApp` calls
`ArcaneServiceExtensions.register()` in `initState`, which registers
`ext.arcane.devtools.invoke` on the current isolate (idempotent across hot
reloads) and attaches an `ArcaneLogBuffer` to the logger to retain recent log
events.

### RPC protocol

The protocol mirrors the framework's consolidated invoke pattern: a single
extension with a `method` + `params` dispatch, and a structured result/error
envelope.

**Extension name:** `ext.arcane.devtools.invoke`

**Request args** (both strings):

| arg      | value                                                                                            |
| -------- | ------------------------------------------------------------------------------------------------ |
| `method` | the method name (see table below)                                                                |
| `params` | a JSON-encoded object, e.g. `{"mode":"dark"}`. Omit or pass `{}` for methods without parameters. |

**Response envelope** (JSON, frame-encoded once):

```json
{ "type": "result", "result": { ...method payload... } }
```

or, on failure:

```json
{ "type": "error", "error": "Invalid argument(s) (mode): ..." }
```

**Methods:**

| Method            | params                                           | returns                                                   |
| ----------------- | ------------------------------------------------ | --------------------------------------------------------- |
| `ping`            | —                                                | `{status: "ok", extension: "ext.arcane.devtools.invoke"}` |
| `overview`        | —                                                | the full snapshot payload (below)                         |
| `set_auth_status` | `{status: "authenticated" \| "unauthenticated"}` | auth state                                                |
| `set_environment` | `{name: "debug" \| "normal"}`                    | environment state                                         |
| `set_theme_mode`  | `{mode: "light" \| "dark" \| "system"}`          | theme state                                               |

Purely invalid inputs (unknown method, malformed `params` JSON, or an out-of-range
value) are caught server-side and reported as `{type: "error", ...}` rather than
crashing the service extension call.

**`overview` payload shape:**

```jsonc
{
  "services": ["CartService", "..."],
  "logging": {
    "initialized": true,
    "interfaces": ["_ArcaneLogCollector"],
    "metadata": {}
  },
  "featureFlags": { "enabled": ["experimentalUI", "analytics"] },
  "auth": { "status": "authenticated", "isSignedIn": true, "interfaceType": null },
  "theme": { "mode": "dark", "followingSystem": false, "customThemeRegistered": false },
  "environment": { "name": "debug", "isDebug": true },
  "recentLogs": [
    {
      "id": 0,
      "timestamp": "2026-09-06T09:14:29.988",
      "level": "info",
      "module": "Heartbeat",
      "method": null,
      "message": "heartbeat #1",
      "metadata": { "tick": 1 }
    }
  ]
}
```

"State" payloads (auth/environment/theme) return the corresponding subsection
after the mutation has been applied, so a caller can confirm the change without a
follow-up `overview`.

### Transport note

The envelope is **not** laid out identically across transports:

- **Native VM service** (`flutter run` on a device/desktop): the service
  extension returns a JSON *string* as `result`; `response.json["result"]` is a
  `String`. DevTools then needs to `jsonDecode` it once to get the envelope.
- **DWDS / Chrome** (web apps): the web layer already decodes the payload, so
  `response.json["result"]` arrives as a **map** — and the outer envelope is
  stripped. For `ping` you see `{status: "ok", ...}` directly, not
  `{type: "result", result: {...}}`.

`ArcaneServiceBridge._invoke` normalizes both shapes. If you write your own
probe/tool against this extension, handle both, or you will see "no data" only
on web. This is the single most common integration bug (we hit it, fixed it).

---

## Repository layout

```
arcane/                                     # repository root
  arcane_framework/                         # the package users depend on
    extension/devtools/                     # hosts the pre-built extension
      build/                                #   pre-compiled web output (gitignored)
      config.yaml                           #   extension metadata for DevTools
    lib/                                    # framework source (registers the extension)
    pubspec.yaml
  arcane_framework_devtools_extension/      # <-- this package
    lib/
      main.dart                             # ArcaneDevToolsExtension (DevToolsExtension)
      src/
        arcane_devtools_page.dart           # banner + 7-tab shell
        common/
          arcane_bridge.dart                # polling, parsing, mutations
          connection_banner.dart
          shared_widgets.dart
        panels/                             # one file per tab
    web/                                    # Flutter web shell (index.html, manifest)
    pubspec.yaml                            # publish_to: none
    README.md                               # this file
    TODO.md                                 # material_ui incompatibility notes
```

---

## Prerequisites

- **Flutter stable** `>= 3.23` and **Dart SDK** `>= 3.5`
  (developed against Flutter 3.47.2 / Dart 3.13.2).
- **Chrome** available on `PATH` for `flutter run -d chrome`.
- Both sibling packages checked out, so the path dependencies resolve:
  - `arcane_framework` (extension source for the protocol + registrar),
  - `arcane_framework_devtools_extension` (this package).

---

## Getting started

```sh
cd arcane_framework_devtools_extension
flutter pub get
```

`pubspec.yaml` pins `devtools_extensions ^0.5.0`, `devtools_app_shared ^0.5.0`,
and `vm_service ^15.3.0`. The extension imports the real `arcane_framework` via
a path dependency (used for types/logging only — see "No public API" below).

> **No public API added to `arcane_framework`.** Everything the extension reads
> goes over the VM service. The framework exposes zero extra API surface for
> DevTools; theme state helpers live in a `part` file and are hidden from the
> barrel.

---

## Development loop

### Analysis and formatting

The package lints with [`arcane_analysis`](https://github.com/hanskokx/arcane_analysis)
(`analysis_options.yaml`). Gate everything on the analyzer being clean:

```sh
dart format lib test
dart analyze
```

`dart analyze` is the **primary quality gate** — see the test caveat below.

### Tests

```sh
flutter test
```

Known caveat: `flutter test` currently fails to *compile* the test suite because
of a pre-existing `devtools_app_shared` / `dart:js_interop` incompatibility on
this Flutter/Dart version (`test/widget_test.dart` is a trivial smoke test that
does not run). Treat **`dart analyze` as the gate**, and keep `widget_test.dart`
updated so it works whenever the upstream incompatibility is resolved.

### Simulated DevTools environment

The fastest dev loop. Wraps the extension in the `SimulatedDevToolsWrapper` —
a mock DevTools shell with a VM-service URI field, action buttons
(`PING`, `TOGGLE THEME`, `FORCE RELOAD`), and a message log. Hot restart works.

```sh
flutter run -d chrome --dart-define=use_simulated_environment=true
```

The URI field must point at a **running app that depends on `arcane_framework`**
(after connecting, paste the app's `Debug service listening on ws://…/ws` URI).
The connection banner at the top of the extension flips to "connected" and the
panels populate.

Same config from VS Code — `.vscode/launch.json` at this package's root:

```json
{
  "configurations": [
    {
      "name": "devtools_extension + simulated environment",
      "cwd": ".",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=use_simulated_environment=true"]
    }
  ]
}
```

### Running against a real DevTools environment

1. Build and copy the extension into `arcane_framework` first
   ([Building the extension](#building-the-extension)).
2. In any Flutter/Dart project, depend on your local `arcane_framework`:

   ```yaml
   dependencies:
     arcane_framework:
       path: /absolute/path/to/arcane/arcane_framework
   ```

   then `flutter pub get`.

3. Run that app. Because `config.yaml` sets `requiresConnection: true`, launch
   the app and open DevTools from the IDE, the printed DevTools URI, or the CLI
   instructions.
4. The extension appears as an **Arcane** tab in the DevTools app bar. Enable it
   from the **Extensions** menu (upper-right) on first use, if prompted.

DevTools **caches** the extension's built assets aggressively. After changing
extension code and re-running `build_and_copy`, reload/restart DevTools
completely — the extension tab is an embedded iFrame and the old build persists
until DevTools itself is reloaded.

---

## End-to-end validation over the VM service

The most reliable smoke test — it bypasses the extension UI and verifies the
protocol against the live app, which is especially important because of the
[string-vs-map transport quirk](#transport-note).

1. Launch a Chrome app that depends on `arcane_framework`:

   ```sh
   flutter run -d chrome --verbose
   # note the line: Debug service listening on ws://127.0.0.1:PORT/TOKEN/ws
   ```

2. Probe it over the VM service. In a scratch Dart CLI package with
   `vm_service` and `web_socket_channel` deps:

   ```dart
   import 'dart:convert';
   import 'package:vm_service/vm_service.dart' as vm;
   import 'package:web_socket_channel/web_socket_channel.dart';

   Future<void> main(List<String> args) async {
     final ws = WebSocketChannel.connect(Uri.parse(args[0]));
     final service = vm.VmService(ws.stream, (m) => ws.sink.add(m));
     final isolate = (await service.getVM()).isolates!.first;

     Future<void> invoke(String method, [Map<String, Object?>? params]) async {
       final res = await service.callServiceExtension(
         'ext.arcane.devtools.invoke',
         isolateId: isolate.id!,
         args: {'method': method, 'params': jsonEncode(params ?? const {})},
       );
       final raw = res.json?['result'];                        // DWDS: map, native: String
       final decoded = raw is String ? jsonDecode(raw) : raw;
       print('$method -> $decoded');
     }

     await invoke('ping');
     await invoke('overview');
     await invoke('set_theme_mode', {'mode': 'dark'});
     await invoke('set_auth_status', {'status': 'authenticated'});
     await invoke('set_theme_mode', {'mode': 'banana'});       // expect error envelope
     await invoke('does_not_exist');                            // expect error envelope
   }
   ```

3. Verify: `ping` returns `status: ok`; `overview` returns all seven sections
   plus recent logs; mutations round-trip and are visible on the next `overview`;
   negative cases return `{type: "error", ...}` instead of throwing an RPCError.

A ready-to-run probe plus a heartbeat target app are kept under
`/tmp/opencode/arcane_bridge_probe` and `/tmp/opencode/arcane_target_app`
(throwaway, outside the repo).

---

## Building the extension

Build instructions and the full release workflow live in the
[arcane_framework CONTRIBUTING.md][framework-contrib]. In short, run the
publish gate, which rebuilds the extension and validates it before the
framework ships:

```sh
cd arcane_framework
dart run tool/publish.dart --dry-run
```

That compiles `lib/main.dart` for web via `devtools_extensions build_and_copy`,
replaces `arcane_framework/extension/devtools/build/` (including the canvaskit
permissions fix), validates the result, then dry-runs the framework publish.

---

## Troubleshooting

| Symptom                                                      | Cause / fix                                                                                                                                                                                    |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Extension shows "No app connected" forever.                  | The app isn't connected to this DevTools instance (`requiresConnection: true`). Run the app and open DevTools from its URI/IDE.                                                                |
| Panels render but show "No state available yet."             | The bridge is connected but `overview` returned nothing. Usually the transport quirk: if you hand-rolled a probe, handle both String and Map `result` (see [Transport note](#transport-note)). |
| Mutations fail with `{type:"error"}`.                        | Server-side validation rejects the value (e.g. `mode: "banana"`). This is expected and reported cleanly.                                                                                       |
| Extension tab still shows the OLD UI after rebuild.          | DevTools caches extension assets. Fully reload/restart DevTools.                                                                                                                               |
| `flutter test` fails to compile.                             | Pre-existing `devtools_app_shared` / `dart:js_interop` incompatibility; use `dart analyze` as the gate.                                                                                        |
| `flutter run -d chrome` print-less output / no `ws://` line. | Run with `--verbose`; the "Debug service listening on `ws://…`" line appears in verbose output.                                                                                                |
| `No MaterialLocalizations found` in extension UI.            | Extension should only use `flutter/material.dart` widgets, never `material_ui` (see `TODO.md`).                                                                                                |
| Missing `build/` in the published framework archive.         | `extension/devtools/.pubignore` is absent — add a `.pubignore` containing `!build` inside `arcane_framework/extension/devtools/`.                                                              |

---

## Resources

- [DevTools extensions docs](https://docs.flutter.dev/tools/devtools/extensions)
- [Build custom DevTools tooling](https://docs.flutter.dev/tools/devtools/custom-tool)
- [`devtools_extensions` on pub.dev](https://pub.dev/packages/devtools_extensions)
- [`devtools_app_shared` on pub.dev](https://pub.dev/packages/devtools_app_shared)
- [DevTools extension config spec](https://github.com/flutter/devtools/blob/master/packages/devtools_extensions/extension_config_spec.md)
- [arcane_framework](https://github.com/hanskokx/arcane_framework)
- [framework-contrib]: https://github.com/hanskokx/arcane_framework/blob/main/CONTRIBUTING.md
