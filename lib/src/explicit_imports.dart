import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart' show RuleContext;
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart'
    show RuleVisitorRegistry;
import 'package:analyzer/dart/ast/ast.dart'
    show ImportDirective, ShowCombinator;
import 'package:analyzer/error/error.dart' show LintCode;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;

class ExplicitImportsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'explicit_imports',
    'Imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        "Add an import prefix (as ...) or restrict imports with show.",
  );

  ExplicitImportsRule()
    : super(
        name: code.name,
        description:
            'Flags imports that do not use an "as" prefix or do not restrict symbols with "show".',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitImportDirective(ImportDirective node) {
    final hasAsPrefix = node.prefix != null;

    // `combinators` includes ShowCombinator / HideCombinator.
    final hasShow = node.combinators.any((c) => c is ShowCombinator);

    // Flag if neither "as" nor "show" is present.
    if (!hasAsPrefix && !hasShow) {
      // Highlight the whole directive (simple + works well in IDEs).
      rule.reportAtNode(node);
    }
  }
}
