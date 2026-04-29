import 'package:analysis_server_plugin/edit/dart/correction_producer.dart'
    show CorrectionApplicability, ResolvedCorrectionProducer;
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart' show RuleContext;
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart'
    show RuleVisitorRegistry;
import 'package:analyzer/dart/ast/ast.dart'
    show
        ExportDirective,
        ImportDirective,
        NamedType,
        ShowCombinator,
        SimpleIdentifier;
import 'package:analyzer/dart/ast/visitor.dart'
    show RecursiveAstVisitor, SimpleAstVisitor;
import 'package:analyzer/dart/element/element.dart'
    show Element, ExtensionElement;
import 'package:analyzer/error/error.dart' show LintCode;
import 'package:analyzer/source/source_range.dart' show SourceRange;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart'
    show ChangeBuilder;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' show FixKind;

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

// -------- Autofix --------

/// A fix producer that adds a `show` combinator to a bare import directive.
///
/// It walks the resolved AST of the file to determine which top-level symbols
/// from the imported library are actually referenced, including named extension
/// elements whose members are called via extension dispatch.  If any usage
/// originates from an unnamed extension the fix is not offered (because unnamed
/// extensions cannot appear in a `show` clause).
class AddShowCombinator extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'dart.fix.explicit_imports.addShow',
    DartFixKindPriority.standard,
    'Add show combinator',
  );

  AddShowCombinator({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(final ChangeBuilder builder) async {
    // Walk up from the covering node to the ImportDirective.
    var node = coveringNode;
    ImportDirective? importDirective;
    while (node != null) {
      if (node is ImportDirective) {
        importDirective = node;
        break;
      }
      node = node.parent;
    }
    if (importDirective == null) return;

    final libraryImport = importDirective.libraryImport;
    if (libraryImport == null) return;

    final namespace = libraryImport.namespace;
    final namespaceMap = namespace.definedNames2;
    if (namespaceMap.isEmpty) return;

    // Build a reverse map: element object → exported name.
    // Skip dotted entries such as "ClassName.staticMember" – the namespace
    // contains both "ClassName" (the type itself) and "ClassName.member"
    // (its static members) as separate keys.  We only care about the
    // top-level name so that the show clause lists "ClassName" rather than
    // "ClassName.member" for each static member.
    final elementToName = <Element, String>{};
    for (final entry in namespaceMap.entries) {
      if (!entry.key.contains('.')) {
        elementToName[entry.value] = entry.key;
      }
    }

    // Walk the unit AST to collect referenced names from this import.
    final usedNames = <String>{};
    var hasUnshowableUsage = false;

    void checkElement(final Element? element) {
      if (element == null) return;

      // Direct match – the identifier resolves to a top-level exported element.
      final name = elementToName[element];
      if (name != null) {
        usedNames.add(name);
        return;
      }

      // Indirect match – the identifier is a member of an exported type
      // (class, mixin, extension, enum, …).
      final enclosing = element.enclosingElement;
      if (enclosing == null) return;

      final enclosingName = elementToName[enclosing];
      if (enclosingName != null) {
        usedNames.add(enclosingName);
        return;
      }

      // If the element is a member of an *unnamed* extension from the imported
      // library we cannot produce a valid show clause: unnamed extensions have
      // no identifier and therefore cannot appear in a `show` combinator.
      if (enclosing is ExtensionElement && enclosing.name == null) {
        final importedLibrary = libraryImport.importedLibrary;
        if (importedLibrary != null &&
            enclosing.library == importedLibrary) {
          hasUnshowableUsage = true;
        }
      }
    }

    unitResult.unit.accept(_UsedElementCollector(checkElement));

    if (hasUnshowableUsage || usedNames.isEmpty) return;

    final sortedNames = usedNames.toList()..sort();

    await builder.addDartFileEdit(file, (final fileBuilder) {
      final combinators = importDirective!.combinators;
      if (combinators.isEmpty) {
        // Insert ' show A, B' before the semicolon.
        fileBuilder.addSimpleInsertion(
          importDirective.semicolon.offset,
          ' show ${sortedNames.join(', ')}',
        );
      } else {
        // Replace any existing combinators (e.g. a lone `hide`) with `show`.
        final first = combinators.first;
        final last = combinators.last;
        fileBuilder.addSimpleReplacement(
          SourceRange(first.offset, last.end - first.offset),
          'show ${sortedNames.join(', ')}',
        );
      }
    });
  }
}

/// Visits every [SimpleIdentifier] in the unit, skipping nodes inside
/// import/export directives so that combinator names are not mistaken for
/// actual usages.
class _UsedElementCollector extends RecursiveAstVisitor<void> {
  final void Function(Element?) _check;

  _UsedElementCollector(this._check);

  @override
  void visitExportDirective(final ExportDirective node) {
    // Do NOT descend – combinator identifiers are not real usages.
  }

  @override
  void visitImportDirective(final ImportDirective node) {
    // Do NOT descend – combinator identifiers are not real usages.
  }

  @override
  void visitNamedType(final NamedType node) {
    // In analyzer 9+ NamedType.name is a Token, not a SimpleIdentifier, so
    // type references like `Random()` are not caught by visitSimpleIdentifier.
    _check(node.element);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    _check(node.element);
    super.visitSimpleIdentifier(node);
  }
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
        description:
            'Flags package:flutter and package:flutter_test imports without "show" or "as".',
        appliesTo: (final uri) {
          final pkg = _packageName(uri);
          return pkg == 'flutter' || pkg == 'flutter_test';
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
          if (pkg == null || pkg == 'flutter' || pkg == 'flutter_test') {
            return false;
          }
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
