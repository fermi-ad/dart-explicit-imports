import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;

mixin ExplicitImportsSharedCases on AnalysisRuleTest {
  Future<void> assertLinted(final String importStmt, final String usage) async {
    await assertDiagnostics('$importStmt\n$usage\n', [
      lint(0, importStmt.length),
    ]);
  }

  Future<void> assertOk(final String importStmt, final String usage) async {
    await assertNoDiagnostics('$importStmt\n$usage\n');
  }
}
