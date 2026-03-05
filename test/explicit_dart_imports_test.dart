import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitDartImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;
import './common.dart'
    show
        ExplicitImportsSharedCases,
        FlutterImportOutOfScopeCase,
        PackageImportOutOfScopeCase,
        RelativeImportOutOfScopeCase;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitDartImportsTest);
  });
}

@reflectiveTest
class ExplicitDartImportsTest extends AnalysisRuleTest
    with
        ExplicitImportsSharedCases,
        FlutterImportOutOfScopeCase,
        PackageImportOutOfScopeCase,
        RelativeImportOutOfScopeCase {
  @override
  String get analysisRule => 'explicit_dart_imports';

  @override
  void setUp() {
    rule = ExplicitDartImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_plain_import_is_linted() async {
    await assertLinted("import 'dart:math';", 'final _ = Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_is_ok() async {
    await assertOk("import 'dart:math' as math;", 'final _ = math.Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_show_is_ok() async {
    await assertOk("import 'dart:math' show Random;", 'final _ = Random();');
  }

  // ignore: non_constant_identifier_names
  void test_import_with_as_and_show_is_ok() async {
    await assertOk(
      "import 'dart:math' as math show Random;",
      'final _ = math.Random();',
    );
  }

  // ignore: non_constant_identifier_names
  void test_import_with_hide_only_is_linted() async {
    await assertLinted("import 'dart:math' hide Random;", 'final _ = pi;');
  }
}
