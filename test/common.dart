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

/// Verifies that plain `dart:` imports are ignored by the rule under test.
/// Mix into any rule test class whose scope is NOT dart: imports.
mixin DartImportOutOfScopeCase on AnalysisRuleTest {
  // ignore: non_constant_identifier_names
  void test_out_of_scope_dart_import_is_not_linted() async {
    await assertNoDiagnostics("import 'dart:math';\nfinal _ = Random();\n");
  }
}

/// Verifies that plain `package:flutter` imports are ignored by the rule under
/// test. Mix into any rule test class whose scope is NOT flutter imports.
mixin FlutterImportOutOfScopeCase on AnalysisRuleTest {
  @override
  void setUp() {
    newPackage(
      'flutter',
    ).addFile('lib/widgets.dart', 'class Widget { const Widget(); }');
    newPackage(
      'flutter_test',
    ).addFile('lib/flutter_test.dart', 'void testWidgets() {}');
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_flutter_import_is_not_linted() async {
    await assertNoDiagnostics(
      "import 'package:flutter/widgets.dart';\nfinal _ = const Widget();\n",
    );
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_flutter_test_import_is_not_linted() async {
    await assertNoDiagnostics(
      "import 'package:flutter_test/flutter_test.dart';\nfinal _ = testWidgets;\n",
    );
  }
}

/// Verifies that plain non-Flutter `package:` imports are ignored by the rule
/// under test. Mix into any rule test class whose scope is NOT package imports.
mixin PackageImportOutOfScopeCase on AnalysisRuleTest {
  @override
  void setUp() {
    newPackage(
      'some_pkg',
    ).addFile('lib/some_pkg.dart', 'class SomePkg { const SomePkg(); }');
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_package_import_is_not_linted() async {
    await assertNoDiagnostics(
      "import 'package:some_pkg/some_pkg.dart';\nfinal _ = const SomePkg();\n",
    );
  }
}

/// Verifies that plain relative imports are ignored by the rule under test.
/// Mix into any rule test class whose scope is NOT relative imports.
mixin RelativeImportOutOfScopeCase on AnalysisRuleTest {
  @override
  void setUp() {
    newFile(
      '$testPackageLibPath/some_local.dart',
      'class SomeLocal { const SomeLocal(); }',
    );
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_relative_import_is_not_linted() async {
    await assertNoDiagnostics(
      "import 'some_local.dart';\nfinal _ = const SomeLocal();\n",
    );
  }
}
