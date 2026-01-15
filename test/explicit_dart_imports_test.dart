import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitDartImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitDartImportsTest);
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
class ExplicitDartImportsTest extends AnalysisRuleTest
    with _ExplicitImportsSharedCases {
  @override
  String get analysisRule => 'explicit_dart_imports';

  @override
  void setUp() {
    rule = ExplicitDartImportsRule();
    super.setUp();

    // Stub a package library inside the synthetic test package ("test") so we
    // can verify "out-of-scope package imports are not linted".
    newFile('$testPackageLibPath/api.dart', r'''
class Api {
  const Api();
}
''');
  }

  // ignore: non_constant_identifier_names
  void test_plain_import_is_linted() async {
    await _assertLinted("import 'dart:math';", 'final _ = Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_is_ok() async {
    await _assertOk("import 'dart:math' as math;", 'final _ = math.Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_show_is_ok() async {
    await _assertOk("import 'dart:math' show Random;", 'final _ = Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_and_show_is_ok() async {
    await _assertOk(
      "import 'dart:math' as math show Random;",
      'final _ = math.Random();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_hide_only_is_linted() async {
    await _assertLinted("import 'dart:math' hide Random;", 'final _ = pi;');
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_package_import_is_not_linted() async {
    await _assertOk(
      "import 'package:test/api.dart';",
      'final _ = const Api();',
    );
  }
}
