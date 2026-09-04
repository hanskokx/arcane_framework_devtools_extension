# arcane_framework_devtools_extension

A DevTools extension for [arcane_framework](https://pub.dev/packages/arcane_framework)
that lets you inspect live runtime state — feature flags, authentication, theme,
environment, logging, and registered services — directly from DevTools.

This package is the **Flutter web app** (source of the extension). It is a companion
to the `arcane_framework` package, which hosts the built extension assets at
`arcane_framework/extension/devtools/`. End-users get this extension automatically
by depending on `arcane_framework`.

## Layout

```
arcane/                         # repository root
  arcane_framework/            # the package users depend on (hosts the extension)
    extension/
      devtools/
        build/                 # pre-compiled extension output (copied here)
        config.yaml
  arcane_framework_devtools_extension/   # this package (extension web app source)
    lib/
    web/
```

## Prerequisites

- Flutter stable (>= 3.23) and Dart >= 3.5
- Chrome available for `flutter run -d chrome`

## Getting dependencies

```sh
flutter pub get
```

## Running tests & analysis

```sh
dart analyze
dart test
dart format --set-exit-if-changed lib test
```

This project uses [arcane_analysis](https://github.com/hanskokx/arcane_analysis) for
linting (see `analysis_options.yaml`).

## Manually testing the extension

During development, run the extension in the **simulated DevTools environment**. This
wraps the extension with a mock DevTools connection so you can iterate with hot restart
instead of embedding it in DevTools:

```sh
flutter run -d chrome --dart-define=use_simulated_environment=true
```

The simulated environment shows your extension next to a panel you can use to:

- Connect to a VM service URI (a test app that depends on `arcane_framework`)
- Trigger actions a user might perform from DevTools (`PING`, `TOGGLE THEME`, `FORCE RELOAD`)
- See the messages passed between the extension and DevTools

### Running the same config from VS Code

Add a launch configuration to `.vscode/launch.json` in a workspace rooted at this
package:

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

### Testing against a real DevTools environment

To exercise the extension the way real users will, use the published layout in
`arcane_framework` (see [Building the extension](#building-the-extension) first to
copy the built assets):

1. Open a test Flutter/Dart project that depends on `arcane_framework` via a path
   or local dependency.
2. Run the test app (if `requiresConnection` is true, as configured) and open DevTools
   from the IDE, the printed URI, or the CLI instructions.
3. Look for the extension's tab in the DevTools app bar. Whether it is enabled is
   controlled from the "Extensions" menu in the upper-right corner of DevTools.

## Building the extension

Build the Flutter web app and copy its output into `arcane_framework/extension/devtools`
following the standard DevTools extensions workflow:

```sh
cd arcane_framework_devtools_extension
flutter pub get
dart run devtools_extensions build_and_copy \
  --source=. \
  --dest=../arcane_framework/extension/devtools
```

Validate that the extension is wired up correctly for loading in DevTools:

```sh
dart run devtools_extensions validate --package=../arcane_framework
```

> Note: `arcane_framework/extension/devtools/build/` is gitignored. To ensure the
> built output is still bundled when `arcane_framework` is published, add a
> `.pubignore` containing `!build` inside `arcane_framework/extension/devtools/`.

## Publishing the extension

The DevTools extension is **not published from this package** — it ships with
`arcane_framework`. Before publishing `arcane_framework`, make sure:

1. `arcane_framework/extension/devtools/config.yaml` exists and is configured
   (name, `issueTracker`, `version`, `materialIconCodePoint`).
2. The built assets are present in `arcane_framework/extension/devtools/build/`
   (run `build_and_copy` as described above).
3. `dart run devtools_extensions validate --package=../arcane_framework` passes.

Then publish `arcane_framework` from its own directory:

```sh
cd ../arcane_framework
flutter pub publish
```

`pub publish` warns if `config.yaml` or a non-empty `build/` directory is missing.

## Adding a development version of the extension to VS Code

VS Code integrates with DevTools extensions for Dart/Flutter projects that depend on
the parent package. To develop against an unreleased `arcane_framework`:

1. In a Flutter/Dart project, add a path dependency on your local `arcane_framework`:

   ```yaml
   dependencies:
     arcane_framework:
       path: /absolute/path/to/arcane/arcane_framework
   ```

   then run `flutter pub get` (or `dart pub get`).

2. Make sure the local `arcane_framework/extension/devtools/build/` is up to date
   (see [Building the extension](#building-the-extension)).

3. Open the test project in VS Code and run it:
   - **If the extension requires a connection** (current config has
     `requiresConnection: true`), launch the app and open DevTools from VS Code or the
     printed URI.
   - **If it doesn't require a connection**, open DevTools directly on the project.
   The extension tab appears in DevTools.

## Updating the development version of the extension in VS Code

After editing code in this package, push the latest build to `arcane_framework` and
reload:

```sh
flutter pub get
dart run devtools_extensions build_and_copy \
  --source=. \
  --dest=../arcane_framework/extension/devtools
```

Then reload/restart DevTools in VS Code so it picks up the new copy in
`arcane_framework/extension/devtools/build/` (DevTools caches the built assets, so a
full DevTools reload is usually required). If `arcane_framework` itself changed (e.g.
new API surface the extension reads), run `flutter pub get` in the test project as well.

## Resources

- [DevTools Extensions documentation](https://docs.flutter.dev/tools/devtools/extensions)
- [devtools_extensions package](https://pub.dev/packages/devtools_extensions)
- [devtools_app_shared package](https://pub.dev/packages/devtools_app_shared)