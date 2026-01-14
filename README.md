# Explicit Imports

A Dart **analyzer plugin** that enforces **explicit imports**.

This plugin flags any `import` directive that does **not** use either:

- an `as` prefix, or
- a `show` combinator

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
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:foo/foo.dart' as foo show Foo;
```

> Note: `hide` **does not** count as explicit. Only `show` or `as` satisfies the rule.

---

## Installation

Currently, since the plugin isn't yet published to a pub registry, you must clone the repo locally in order to use the plugin. After cloning, add the following to your `analysis_options.yaml`:

```yaml
plugins:
  explicit_imports:
    path: /path/to/dart-explicit-imports
```

Then you should restart your Dart analysis server for the change to take effect.

---

## Rule

### `explicit_imports`

**Message**
> Imports must use either a "show" combinator or an "as" prefix.

---

## Development

### Run tests
```bash
dart test
```

### Implementation

The plugin is implemented using the official `analyzer_plugin` API and registers a custom lint rule that inspects `ImportDirective` nodes.

---

## Motivation

Explicit imports:
- make APIs easier to reason about
- reduce accidental name conflicts
- improve long-term maintainability of large Dart and Flutter codebases

---
