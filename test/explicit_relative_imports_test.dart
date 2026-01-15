import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitRelativeImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;
import './common.dart' show ExplicitImportsSharedCases;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitRelativeImportsTest);
  });
}

@reflectiveTest
class ExplicitRelativeImportsTest extends AnalysisRuleTest
    with ExplicitImportsSharedCases {
  @override
  void setUp() {
    // Create a local library the test file can import relatively.
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {
  const Foo();
}

const int fooValue = 1;
''');

    rule = ExplicitRelativeImportsRule();
    super.setUp();
  }

  static const _relImport = "import 'foo.dart';";
  static const _relImportAs = "import 'foo.dart' as f;";
  static const _relImportShow = "import 'foo.dart' show Foo;";
  static const _relImportAsShow = "import 'foo.dart' as f show Foo;";
  static const _relImportHideOnly = "import 'foo.dart' hide Foo;";

  // ignore: non_constant_identifier_names
  void test_plain_relative_import_is_linted() async {
    await assertLinted(_relImport, 'final _ = const Foo();');
  }

  // ignore: non_constant_identifier_names
  void test_relative_import_with_as_is_ok() async {
    await assertOk(_relImportAs, 'final _ = const f.Foo();');
  }

  // ignore: non_constant_identifier_names
  void test_relative_import_with_show_is_ok() async {
    await assertOk(_relImportShow, 'final _ = const Foo();');
  }

  // ignore: non_constant_identifier_names
  void test_relative_import_with_as_and_show_is_ok() async {
    await assertOk(_relImportAsShow, 'final _ = const f.Foo();');
  }

  // ignore: non_constant_identifier_names
  void test_relative_import_with_hide_only_is_linted() async {
    // Linted because it's neither `show` nor `as`.
    // Usage must not reference the hidden symbol.
    await assertLinted(_relImportHideOnly, 'final _ = fooValue;');
  }

  // ignore: non_constant_identifier_names
  void test_out_of_scope_dart_import_is_not_linted() async {
    await assertOk("import 'dart:math';", 'final _ = Random();');
  }
}
