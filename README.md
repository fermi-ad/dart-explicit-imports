# Explicit Imports

A Dart **analyzer plugin** that enforces **explicit imports**.

This plugin flags any `import` directive that does **not** use either:

- a `show` combinator, or
- as `as` prefix

The goal is to reduce namespace pollution and make dependencies more explicit and readable.

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

## Installation

Currently, since the plugin isn't yet published to a pub registry, **you must clone the repo locally** in order to use the plugin:

```bash
$ git clone https://github.com/fermi-ad/dart-explicit-imports.git
```

After cloning, add the following to your `analysis_options.yaml`:

```yaml
plugins:
  explicit_imports:
    path: /path/to/dart-explicit-imports
    diagnostics:
      explicit_dart_imports: true
      explicit_flutter_imports: true
      explicit_package_imports: true
      explicit_relative_imports: true
```

Then **restart your Dart analysis server (or IDE)** for the changes to take effect.

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

## Development

### Run tests
```bash
dart test
```

---

## Motivation

Explicit imports:
- make APIs easier to reason about
- reduce accidental name conflicts
- improve long-term maintainability of large Dart and Flutter codebases
