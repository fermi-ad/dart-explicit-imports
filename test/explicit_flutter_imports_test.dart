import 'package:analyzer_testing/analysis_rule/analysis_rule.dart'
    show AnalysisRuleTest;
import 'package:explicit_imports/src/explicit_imports.dart'
    show ExplicitFlutterImportsRule;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;
import './common.dart' show ExplicitImportsSharedCases;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExplicitFlutterImportsTest);
  });
}

@reflectiveTest
class ExplicitFlutterImportsTest extends AnalysisRuleTest
    with ExplicitImportsSharedCases {
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

void runApp() {}
''');

    rule = ExplicitFlutterImportsRule();
    super.setUp();
  }

  // ignore: non_constant_identifier_names
  void test_plain_flutter_import_is_linted() async {
    await assertLinted(
      "import 'package:flutter/widgets.dart';",
      "final _ = const Widget();",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_as_is_ok() async {
    await assertOk(
      "import 'package:flutter/widgets.dart' as w;",
      "final _ = const w.Widget();",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_show_is_ok() async {
    await assertOk(
      "import 'package:flutter/widgets.dart' show Widget;",
      "final _ = const Widget();",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_as_and_show_is_ok() async {
    await assertOk(
      "import 'package:flutter/widgets.dart' as w show Widget;",
      "final _ = const w.Widget();",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_import_with_hide_only_is_linted() async {
    await assertLinted(
      "import 'package:flutter/widgets.dart' hide Widget;",
      "final _ = runApp;",
    );
  }
}
