import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitImportsTest);
  });
}

@reflectiveTest
class ExplicitImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ExplicitImportsRule();
    super.setUp();
  }

  void test_plain_import_is_linted() async {
    await assertDiagnostics(
      r"""
import 'dart:math';
final _ = Random();
""",
      [lint(0, 19)],
    );
  }

  void test_import_with_as_is_ok() async {
    await assertNoDiagnostics(r"""
import 'dart:math' as math;
final _ = math.Random();
""");
  }

  void test_import_with_show_is_ok() async {
    await assertNoDiagnostics(r"""
import 'dart:math' show Random;
final _ = Random();
""");
  }

  void test_import_with_as_and_show_is_ok() async {
    await assertNoDiagnostics(r"""
import 'dart:math' as math show Random;
final _ = math.Random();
""");
  }

  void test_import_with_hide_only_is_linted() async {
    await assertDiagnostics(
      r"""
import 'dart:math' hide Random;
final _ = pi;
""",
      [lint(0, 31)],
    );
  }
}
