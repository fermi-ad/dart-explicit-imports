import 'package:analysis_server_plugin/edit/dart/correction_producer.dart'
    show CorrectionProducerContext;
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart'
    show DartFixContext;
import 'package:analyzer/dart/analysis/results.dart' show ResolvedLibraryResult;
import 'package:analyzer/dart/analysis/session.dart' show AnalysisSession;
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/instrumentation/service.dart'
    show InstrumentationService;
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart'
    show ChangeBuilder;
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart'
    show ChangeWorkspace;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show
        AddShowCombinator,
        ExplicitDartImportsRule,
        ExplicitPackageImportsRule,
        ExplicitRelativeImportsRule;
import 'package:test/test.dart' show expect, isEmpty, isNotEmpty;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

import './common.dart' show ExplicitImportsSharedCases;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AutofixDartTest);
    defineReflectiveTests(AutofixPackageTest);
    defineReflectiveTests(AutofixRelativeTest);
  });
}

// ---------------------------------------------------------------------------
// Shared mixin that adds fix-assertion capability on top of AnalysisRuleTest.
// ---------------------------------------------------------------------------

mixin _FixTestMixin on AnalysisRuleTest {
  /// Asserts that applying [AddShowCombinator] to [code] (which must contain
  /// exactly one lint) produces [expected].
  Future<void> assertFix(
    final String code,
    final String expected,
  ) async {
    // Populate `result` by resolving the file via the standard diagnostic path.
    newFile(testFile.path, code);
    result = await resolveFile(convertPath(testFile.path));

    final diagnostic = result.diagnostics.firstWhere(
      (final d) => d.diagnosticCode.name == rule.name,
    );

    final session = result.session;
    final libraryResult =
        await session.getResolvedLibrary(result.path) as ResolvedLibraryResult;

    final workspace = _SingleSessionWorkspace(session, result.path);

    final fixContext = DartFixContext(
      instrumentationService: InstrumentationService.NULL_SERVICE,
      workspace: workspace,
      libraryResult: libraryResult,
      unitResult: result,
      error: diagnostic,
    );

    final correctionContext = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: result,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    final producer = AddShowCombinator(context: correctionContext);
    final builder = ChangeBuilder(
      workspace: workspace,
      defaultEol: producer.defaultEol,
    );
    await producer.compute(builder);

    final edits = builder.sourceChange.edits;
    expect(edits, isNotEmpty, reason: 'Expected a fix to be produced');

    final fileEdit = edits.firstWhere((final e) => e.file == result.path);
    final fixedCode = SourceEdit.applySequence(code, fileEdit.edits);
    expect(fixedCode, expected);
  }

  /// Asserts that [AddShowCombinator] does NOT produce a fix for [code].
  Future<void> assertNoFix(final String code) async {
    newFile(testFile.path, code);
    result = await resolveFile(convertPath(testFile.path));

    final lintDiagnostics =
        result.diagnostics.where((final d) => d.diagnosticCode.name == rule.name).toList();
    expect(lintDiagnostics, isNotEmpty,
        reason: 'Expected the lint "${rule.name}" to fire');

    final diagnostic = lintDiagnostics.first;
    final session = result.session;
    final libraryResult =
        await session.getResolvedLibrary(result.path) as ResolvedLibraryResult;

    final workspace = _SingleSessionWorkspace(session, result.path);

    final fixContext = DartFixContext(
      instrumentationService: InstrumentationService.NULL_SERVICE,
      workspace: workspace,
      libraryResult: libraryResult,
      unitResult: result,
      error: diagnostic,
    );

    final correctionContext = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: result,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    final producer = AddShowCombinator(context: correctionContext);
    final builder = ChangeBuilder(
      workspace: workspace,
      defaultEol: producer.defaultEol,
    );
    await producer.compute(builder);

    expect(builder.sourceChange.edits, isEmpty,
        reason: 'Expected no fix to be produced');
  }
}

// ---------------------------------------------------------------------------
// Minimal ChangeWorkspace implementation for tests.
// ---------------------------------------------------------------------------

final class _SingleSessionWorkspace implements ChangeWorkspace {
  final AnalysisSession _session;
  final String _path;

  _SingleSessionWorkspace(this._session, this._path);

  @override
  ResourceProvider get resourceProvider => _session.resourceProvider;

  @override
  bool containsFile(final String path) => path == _path;

  @override
  AnalysisSession? getSession(final String path) => _session;
}

// ---------------------------------------------------------------------------
// dart: import autofix tests
// ---------------------------------------------------------------------------

@reflectiveTest
class AutofixDartTest extends AnalysisRuleTest
    with ExplicitImportsSharedCases, _FixTestMixin {
  @override
  void setUp() {
    rule = ExplicitDartImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_single_used_symbol() async {
    await assertFix(
      "import 'dart:math';\nfinal _ = pi;\n",
      "import 'dart:math' show pi;\nfinal _ = pi;\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_multiple_used_symbols_in_sorted_order() async {
    await assertFix(
      "import 'dart:math';\nfinal a = pi; final b = e;\n",
      "import 'dart:math' show e, pi;\nfinal a = pi; final b = e;\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_class_symbol() async {
    await assertFix(
      "import 'dart:math';\nfinal _ = Random();\n",
      "import 'dart:math' show Random;\nfinal _ = Random();\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_replaces_hide_combinator() async {
    await assertFix(
      "import 'dart:math' hide Random;\nfinal _ = pi;\n",
      "import 'dart:math' show pi;\nfinal _ = pi;\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_no_fix_when_no_symbols_used() async {
    await assertNoFix("import 'dart:math';\n");
  }
}

// ---------------------------------------------------------------------------
// package: import autofix tests
// ---------------------------------------------------------------------------

@reflectiveTest
class AutofixPackageTest extends AnalysisRuleTest
    with ExplicitImportsSharedCases, _FixTestMixin {
  @override
  void setUp() {
    newPackage('my_pkg').addFile('lib/my_pkg.dart', '''
class Foo {}
class Bar {}
extension FooExt on Foo {
  void hello() {}
}
extension on Bar {
  void world() {}
}
''');
    rule = ExplicitPackageImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_used_class() async {
    await assertFix(
      "import 'package:my_pkg/my_pkg.dart';\nfinal _ = Foo();\n",
      "import 'package:my_pkg/my_pkg.dart' show Foo;\nfinal _ = Foo();\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_named_extension_for_extension_method() async {
    await assertFix(
      "import 'package:my_pkg/my_pkg.dart';\nvoid f() { Foo().hello(); }\n",
      "import 'package:my_pkg/my_pkg.dart' show Foo, FooExt;\nvoid f() { Foo().hello(); }\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_multiple_classes() async {
    await assertFix(
      "import 'package:my_pkg/my_pkg.dart';\nfinal a = Foo(); final b = Bar();\n",
      "import 'package:my_pkg/my_pkg.dart' show Bar, Foo;\nfinal a = Foo(); final b = Bar();\n",
    );
  }
}

// ---------------------------------------------------------------------------
// relative import autofix tests
// ---------------------------------------------------------------------------

@reflectiveTest
class AutofixRelativeTest extends AnalysisRuleTest
    with ExplicitImportsSharedCases, _FixTestMixin {
  @override
  void setUp() {
    newFile('$testPackageLibPath/helpers.dart', '''
class Helper {}
int helperValue = 42;
''');
    rule = ExplicitRelativeImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_used_class() async {
    await assertFix(
      "import 'helpers.dart';\nfinal _ = Helper();\n",
      "import 'helpers.dart' show Helper;\nfinal _ = Helper();\n",
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_fix_adds_multiple_used_symbols() async {
    await assertFix(
      "import 'helpers.dart';\nfinal a = Helper(); final b = helperValue;\n",
      "import 'helpers.dart' show Helper, helperValue;\nfinal a = Helper(); final b = helperValue;\n",
    );
  }
}
