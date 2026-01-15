import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart' show RuleContext;
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart'
    show RuleVisitorRegistry;
import 'package:analyzer/dart/ast/ast.dart'
    show ImportDirective, ShowCombinator;
import 'package:analyzer/error/error.dart' show LintCode;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;

typedef ImportFilter = bool Function(String uri);

abstract class _ExplicitImportsBaseRule extends AnalysisRule {
  final LintCode _code;
  final ImportFilter _appliesTo;

  _ExplicitImportsBaseRule({
    required final LintCode code,
    required super.description,
    required final ImportFilter appliesTo,
  }) : _code = code,
       _appliesTo = appliesTo,
       super(name: code.name);

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    final RuleVisitorRegistry registry,
    final RuleContext context,
  ) {
    registry.addImportDirective(this, _Visitor(this, _appliesTo));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final ImportFilter appliesTo;

  _Visitor(this.rule, this.appliesTo);

  @override
  void visitImportDirective(final ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;
    if (!appliesTo(uri)) return;

    final hasAsPrefix = node.prefix != null;
    final hasShow = node.combinators.any((final c) => c is ShowCombinator);

    if (!hasAsPrefix && !hasShow) {
      rule.reportAtNode(node);
    }
  }
}

// -------- Helpers --------

String? _packageName(final String uri) {
  if (!uri.startsWith('package:')) return null;
  final rest = uri.substring('package:'.length);
  final slash = rest.indexOf('/');
  return slash == -1 ? rest : rest.substring(0, slash);
}

bool _isRelative(final String uri) {
  // Covers `import 'foo.dart';`, `./foo.dart`, `../foo.dart`
  // (Any URI with no scheme and not starting with package:/dart:/file:)
  final hasScheme = uri.contains(':'); // e.g. dart:, package:, file:
  if (hasScheme) return false;
  return true;
}

// -------- Concrete rules --------

class ExplicitDartImportsRule extends _ExplicitImportsBaseRule {
  static const LintCode code = LintCode(
    'explicit_dart_imports',
    'Dart SDK imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        'Restrict imports with show, or add an import prefix (as ...).',
  );

  ExplicitDartImportsRule()
    : super(
        code: code,
        description: 'Flags dart: imports without "show" or "as".',
        appliesTo: (final uri) => uri.startsWith('dart:'),
      );
}

class ExplicitFlutterImportsRule extends _ExplicitImportsBaseRule {
  static const LintCode code = LintCode(
    'explicit_flutter_imports',
    'Flutter imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        'Restrict imports with show, or add an import prefix (as ...).',
  );

  ExplicitFlutterImportsRule()
    : super(
        code: code,
        description: 'Flags package:flutter imports without "show" or "as".',
        appliesTo: (final uri) {
          final pkg = _packageName(uri);
          return pkg == 'flutter';
        },
      );
}

class ExplicitPackageImportsRule extends _ExplicitImportsBaseRule {
  static const LintCode code = LintCode(
    'explicit_package_imports',
    'Package imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        'Restrict imports with show, or add an import prefix (as ...).',
  );

  ExplicitPackageImportsRule()
    : super(
        code: code,
        description:
            'Flags non-Flutter package: imports without "show" or "as".',
        appliesTo: (final uri) {
          final pkg = _packageName(uri);
          if (pkg == null) return false;
          if (pkg == 'flutter') return false;
          return true;
        },
      );
}

class ExplicitRelativeImportsRule extends _ExplicitImportsBaseRule {
  static const LintCode code = LintCode(
    'explicit_relative_imports',
    'Relative imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        'Restrict imports with show, or add an import prefix (as ...).',
  );

  ExplicitRelativeImportsRule()
    : super(
        code: code,
        description: 'Flags relative imports without "show" or "as".',
        appliesTo: _isRelative,
      );
}
