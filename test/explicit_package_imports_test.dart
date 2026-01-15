import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitPackageImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitPackageImportsTest);
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
}

@reflectiveTest
class ExplicitPackageImportsTest extends AnalysisRuleTest
    with _ExplicitImportsSharedCases {
  @override
  String get analysisRule => 'explicit_package_imports';

  @override
  void setUp() {
    rule = ExplicitPackageImportsRule();
    super.setUp();

    // Stub a library inside the synthetic test package (named "test" in this harness).
    newFile('$testPackageLibPath/api.dart', r'''
class Api {
  const Api();
}

const int apiVersion = 1;
''');
  }

  // ignore: non_constant_identifier_names
  void test_plain_package_import_is_linted() async {
    await _assertLinted(
      "import 'package:test/api.dart';",
      'final _ = const Api();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_is_ok() async {
    await _assertOk(
      "import 'package:test/api.dart' as t;",
      'final _ = const t.Api();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_show_is_ok() async {
    await _assertOk(
      "import 'package:test/api.dart' show Api;",
      'final _ = const Api();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_and_show_is_ok() async {
    await _assertOk(
      "import 'package:test/api.dart' as t show Api;",
      'final _ = const t.Api();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_hide_only_is_linted() async {
    // Still "used", so the import isn't flagged as unused.
    await _assertLinted(
      "import 'package:test/api.dart' hide Api;",
      'final _ = apiVersion;',
    );
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_dart_import_is_not_linted() async {
    await _assertOk("import 'dart:math';", 'final _ = Random();');
  }
}
