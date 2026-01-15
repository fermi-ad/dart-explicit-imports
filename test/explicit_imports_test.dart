import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show
        ExplicitDartImportsRule,
        ExplicitFlutterImportsRule,
        ExplicitPackageImportsRule,
        ExplicitRelativeImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitDartImportsTest);
    defineReflectiveTests(ExplicitFlutterImportsTest);
    defineReflectiveTests(ExplicitPackageImportsTest);
    defineReflectiveTests(ExplicitRelativeImportsTest);
  });
}

mixin _ExplicitImportsSharedCases on AnalysisRuleTest {
  Future<void> _assertLinted(
    final String importStmt,
    final String usage,
  ) async {
    await assertDiagnostics('$importStmt\n$usage\n', [
      lint(0, importStmt.length),
    ]);
  }

  Future<void> _assertOk(final String importStmt, final String usage) async {
    await assertNoDiagnostics('$importStmt\n$usage\n');
  }

  /// Common “in-scope” behavior: plain import is linted, and `as`/`show` are ok,
  /// and `hide`-only is linted.
  Future<void> runCommonCases({
    required final String plainImport,
    required final String plainUsage,
    required final String asImport,
    required final String asUsage,
    required final String showImport,
    required final String showUsage,
    required final String asShowImport,
    required final String asShowUsage,
    required final String hideOnlyImport,
    required final String hideOnlyUsage,
  }) async {
    await _assertLinted(plainImport, plainUsage);
    await _assertOk(asImport, asUsage);
    await _assertOk(showImport, showUsage);
    await _assertOk(asShowImport, asShowUsage);
    await _assertLinted(hideOnlyImport, hideOnlyUsage);
  }
}

@reflectiveTest
class ExplicitDartImportsTest extends AnalysisRuleTest
    with _ExplicitImportsSharedCases {
  @override
  void setUp() {
    rule = ExplicitDartImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_common_cases_for_dart_imports() async {
    await runCommonCases(
      plainImport: "import 'dart:math';",
      plainUsage: 'final _ = Random();',
      asImport: "import 'dart:math' as math;",
      asUsage: 'final _ = math.Random();',
      showImport: "import 'dart:math' show Random;",
      showUsage: 'final _ = Random();',
      asShowImport: "import 'dart:math' as math show Random;",
      asShowUsage: 'final _ = math.Random();',
      hideOnlyImport: "import 'dart:math' hide Random;",
      hideOnlyUsage: 'final _ = pi;',
    );
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_package_import_is_not_linted() async {
    await _assertOk(
      "import 'package:explicit_imports/src/explicit_imports.dart';",
      'final _ = ExplicitImportsDartRule();',
    );
  }
}

@reflectiveTest
class ExplicitFlutterImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    // Stub out the `flutter` package so `package:flutter/widgets.dart` resolves.
    //
    // Per the docs:
    // - call newPackage in setUp
    // - do it before super.setUp()
    // - stubs can be minimal (bodies/types simplified)
    // :contentReference[oaicite:1]{index=1}
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
''');

    // Optional: if your rule also considers flutter_test in-scope and you want tests.
    newPackage('flutter_test').addFile('lib/flutter_test.dart', r'''
void test(Object? description, dynamic body()) {}
''');

    rule = ExplicitFlutterImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_plain_flutter_import_is_linted() async {
    const importStmt = "import 'package:flutter/widgets.dart';";
    await assertDiagnostics(
      '''
$importStmt
final _ = const Widget();
''',
      [lint(0, importStmt.length)],
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_as_is_ok() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as w;
final _ = const w.Widget();
''');
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_show_is_ok() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' show Widget;
final _ = const Widget();
''');
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_as_and_show_is_ok() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as w show Widget;
final _ = const w.Widget();
''');
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_hide_only_is_linted() async {
    const importStmt = "import 'package:flutter/widgets.dart' hide Widget;";
    await assertDiagnostics(
      '''
$importStmt
// Keep the file valid; don't reference Widget (it's hidden).
final _ = 0;
''',
      [lint(0, importStmt.length)],
    );
  }
}

@reflectiveTest
class ExplicitPackageImportsTest extends AnalysisRuleTest
    with _ExplicitImportsSharedCases {
  @override
  void setUp() {
    rule = ExplicitPackageImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_common_cases_for_package_imports() async {
    await runCommonCases(
      plainImport:
          "import 'package:explicit_imports/src/explicit_imports.dart';",
      plainUsage: 'final _ = ExplicitImportsPackageRule();',
      asImport:
          "import 'package:explicit_imports/src/explicit_imports.dart' as ei;",
      asUsage: 'final _ = ei.ExplicitImportsPackageRule();',
      showImport:
          "import 'package:explicit_imports/src/explicit_imports.dart' show ExplicitImportsPackageRule;",
      showUsage: 'final _ = ExplicitImportsPackageRule();',
      asShowImport:
          "import 'package:explicit_imports/src/explicit_imports.dart' as ei show ExplicitImportsPackageRule;",
      asShowUsage: 'final _ = ei.ExplicitImportsPackageRule();',
      // “hide-only” should still be linted because it’s not `show` and not `as`.
      hideOnlyImport:
          "import 'package:explicit_imports/src/explicit_imports.dart' hide ExplicitImportsPackageRule;",
      hideOnlyUsage: 'final _ = ExplicitImportsDartRule();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_dart_import_is_not_linted() async {
    await _assertOk("import 'dart:math';", 'final _ = Random();');
  }
}

@reflectiveTest
class ExplicitRelativeImportsTest extends AnalysisRuleTest
    with _ExplicitImportsSharedCases {
  @override
  void setUp() {
    // Create a local library the test file can import relatively.
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {
  const Foo();
}
''');

    rule = ExplicitRelativeImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_common_cases_for_relative_imports() async {
    await runCommonCases(
      plainImport: "import 'foo.dart';",
      plainUsage: 'final _ = const Foo();',
      asImport: "import 'foo.dart' as f;",
      asUsage: 'final _ = const f.Foo();',
      showImport: "import 'foo.dart' show Foo;",
      showUsage: 'final _ = const Foo();',
      asShowImport: "import 'foo.dart' as f show Foo;",
      asShowUsage: 'final _ = const f.Foo();',
      hideOnlyImport: "import 'foo.dart' hide Foo;",
      // Still *uses* Foo via a different path so the import isn’t unused; the
      // point is the import statement itself is “hide-only”.
      hideOnlyUsage: 'final _ = ExplicitImportsRelativeRule();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_dart_import_is_not_linted() async {
    await _assertOk("import 'dart:math';", 'final _ = Random();');
  }
}
