# Explicit Imports

A Dart **analyzer plugin** that enforces **explicit imports**.

This plugin flags any `import` directive that does **not** use either:

- a `show` combinator, or
- an `as` prefix

The goal is to reduce namespace pollution and make dependencies more explicit and readable.

---

## Installation

Add `explicit_imports` to `analysis_options.yaml` under a top-level `plugins` section:

```yaml
plugins:
  explicit_imports:
    version: ^1.0.3
    diagnostics:
      explicit_dart_imports: true
      explicit_flutter_imports: true
      explicit_package_imports: true
      explicit_relative_imports: true
```

Then **restart your Dart analysis server (or IDE)** for the change to take effect.

> Note: You do **not** need to add `explicit_imports` to your `pubspec.yaml`.

---

## What it flags

❌ **Linted**
```dart
import 'dart:math';
import 'package:foo/foo.dart' hide Bar;
```

✅ **Allowed**
```dart
import 'dart:math' show Random;
import 'dart:math' show Random, pi;
import 'dart:math' as math;
import 'package:foo/foo.dart' as foo show Foo;
```

> Note: `hide` **does not** count as explicit. Only `show` or `as` satisfies the rule.

---

## Rules

As seen above, the plugin splits imports into four separate rules for convenience, allowing you to enable or disable linting for certain categories as desired.

> For instance, **Flutter developers may want to disable the Flutter imports rule** to prevent needing to list (or prepend to) all of the many widgets imported in a file.

All rules share the same behavior: the import must include either a `show` combinator or an `as` prefix.

### `explicit_dart_imports`
Applies to core `dart:` imports.

### `explicit_flutter_imports`
Applies to Flutter imports (`package:flutter/...` and `package:flutter_test/...`).

### `explicit_package_imports`
Applies to all other (i.e. non-Flutter) `package:` imports.

### `explicit_relative_imports`
Applies to relative imports (e.g. `import 'foo.dart';`, `./foo.dart`, `../foo.dart`).

---

## Ignoring rules

To suppress a diagnostic on a particular import, add an `// ignore:` comment above the import with the relevant rule name:

```dart
// ignore: explicit_imports/explicit_dart_imports
import 'dart:math';
// ignore: explicit_imports/explicit_package_imports
import 'package:foo/foo.dart';
```

---

## Motivation

Explicit imports
- make APIs easier to reason about
- reduce accidental name conflicts
- improve long-term maintainability of large Dart and Flutter codebases
