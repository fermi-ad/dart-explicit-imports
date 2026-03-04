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
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

void runApp() {}
''');

    newPackage('flutter_test').addFile('lib/flutter_test.dart', r'''
void testWidgets(String description, dynamic Function() callback) {}
void setUp(dynamic Function() callback) {}
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

  // ignore: non_constant_identifier_names
  void test_plain_flutter_test_import_is_linted() async {
    await assertLinted(
      "import 'package:flutter_test/flutter_test.dart';",
      "final _ = testWidgets;",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_test_import_with_show_is_ok() async {
    await assertOk(
      "import 'package:flutter_test/flutter_test.dart' show testWidgets;",
      "final _ = testWidgets;",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_test_import_with_as_is_ok() async {
    await assertOk(
      "import 'package:flutter_test/flutter_test.dart' as ft;",
      "final _ = ft.testWidgets;",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_test_import_with_as_and_show_is_ok() async {
    await assertOk(
      "import 'package:flutter_test/flutter_test.dart' as ft show testWidgets;",
      "final _ = ft.testWidgets;",
    );
  }

  // ignore: non_constant_identifier_names
  void test_flutter_test_import_with_hide_only_is_linted() async {
    await assertLinted(
      "import 'package:flutter_test/flutter_test.dart' hide testWidgets;",
      "final _ = setUp;",
    );
  }
}
