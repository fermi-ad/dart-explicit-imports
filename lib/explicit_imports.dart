import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Entrypoint required by custom_lint.
PluginBase createPlugin() => _ExplicitImportsPlugin();

class _ExplicitImportsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ExplicitImportsRule(),
      ];
}

class ExplicitImportsRule extends DartLintRule {
  ExplicitImportsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'explicit_imports',
    problemMessage:
        'Imports must use either a "show" combinator or an "as" prefix.',
    correctionMessage:
        'Add an import prefix (as ...) or restrict imports with show.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((ImportDirective node) {
      final hasAsPrefix = node.prefix != null;
      final hasShow = node.combinators.any((c) => c is ShowCombinator);

      if (!hasAsPrefix && !hasShow) {
        reporter.atNode(node, code);
      }
    });
  }
}
