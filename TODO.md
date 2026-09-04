# TODO: `material_ui` vs DevTools extensions compatibility

## Context

`arcane_framework_devtools_extension` is a Flutter DevTools extension that
inspects `arcane_framework` services. `arcane_framework` v3.0.0-dev.1 depends on
`material_ui` (a decoupled re-export of the Material widget library) rather than
`package:flutter/material.dart` directly.

The DevTools extensions framework (`devtools_extensions`) provides its own
`DevToolsExtension` wrapper widget, which renders a `MaterialApp` built from
`package:flutter/material.dart` (the standard Flutter types). This means inside
a DevTools extension, `MaterialLocalizations`, `ThemeData`, `ThemeMode`, etc.
are always Flutter's types — never `material_ui`'s.

The extension's UI works fine using `package:flutter/material.dart` directly
because it renders under DevTools' Flutter-based `MaterialApp`. The only friction
is where our code must interoperate with `arcane_framework`'s *typed* APIs, which
return `material_ui` types.

## The problem

`material_ui` and `package:flutter/material.dart` define **completely separate**
type families. A `material_ui.ThemeData` is not assignable to a
`flutter.ThemeData`, a `material_ui.ThemeMode` is not a `flutter.ThemeMode`, and
`material_ui.MaterialLocalizations` is not `flutter.MaterialLocalizations`.

Concretely, in this extension we had to:

- Keep using `flutter/material.dart` for all UI widgets so they render under the
  DevTools `MaterialApp` (which provides Flutter's `MaterialLocalizations`).
- In `lib/src/panels/theme_panel.dart`, import `material_ui`'s `ThemeMode` and
  `ThemeData` (hiding Flutter's) so we can switch-compare and read theme values
  returned by `Arcane.theme` / `Arcane.theme.currentThemeMode`, which are typed
  with `material_ui` types.

## Why we can't fully adopt `material_ui` in this package

Because DevTools extensions render inside DevTools' own `MaterialApp` (built from
`package:flutter/material.dart`), any widget tree provided by the extension must
use Flutter widgets. A `material_ui.MaterialLocalizations` delegate is **not**
satisfied by DevTools' Flutter-based `MaterialApp`, so using `material_ui`
widgets (e.g. `TabBar`) inside the extension throws
`No MaterialLocalizations found`. Only Flutter widgets work.

## Action item

File a bug report / feature request in the **`material_ui`** package repository
so that DevTools extensions can be built against it (or so that its types can be
used interchangeably with Flutter's).

Suggested content:

- **Title**: "DevTools extensions are incompatible with `material_ui` types"
- **Package/version**: `material_ui` (`^1.0.0` / `1.1.1`) used by
  `arcane_framework` v3.0.0-dev.1
- **Environment**: Flutter stable 3.47.2, Dart 3.13.2, macOS
- **Description**:
  - `material_ui` and `package:flutter/material.dart` expose non-interchangeable
    type families (`ThemeData`, `ThemeMode`, `MaterialLocalizations`, `Color`,
    collection types, etc.).
  - The DevTools extensions framework (`devtools_extensions` v0.5.x) renders the
    extension inside its own `MaterialApp` built from `flutter/material.dart`
    and supplies **Flutter's** `MaterialLocalizations`.
  - Therefore an extension that wants to render DevTools-compatible UI cannot use
    `material_ui` widgets (they fail `debugCheckHasMaterialLocalizations`), and
    any code reading `material_ui`-typed values (e.g. `Arcane.theme.currentTheme`)
    must manually bridge or hide imports between the two libraries.
  - Feature request: provide `material_ui` types that are assignable to /
    interchangeable with Flutter's, or make `material_ui` delegate to Flutter's
    runtime types so both libraries share the same `ThemeData`, `ThemeMode`, and
    `MaterialLocalizations` types.

## Current workaround

This extension uses `package:flutter/material.dart` for all UI and uses a single
`show` import of `material_ui` in `theme_panel.dart` (hiding Flutter's
`ThemeMode`/`ThemeData`) to interoperate with `arcane_framework`'s typed API.
If `material_ui` becomes interchangeable with Flutter's types, remove that
`material_ui` import and use `flutter/material.dart` types everywhere.
