import 'package:analysis_server_plugin/plugin.dart' show Plugin;
import 'package:analysis_server_plugin/registry.dart' show PluginRegistry;
import 'src/explicit_imports.dart'
    show
        ExplicitDartImportsRule,
        ExplicitFlutterImportsRule,
        ExplicitPackageImportsRule,
        ExplicitRelativeImportsRule;

final plugin = ExplicitImportsPlugin();

class ExplicitImportsPlugin extends Plugin {
  @override
  String get name => 'Explicit imports plugin';

  @override
  void register(final PluginRegistry registry) {
    registry.registerLintRule(ExplicitDartImportsRule());
    registry.registerLintRule(ExplicitFlutterImportsRule());
    registry.registerLintRule(ExplicitPackageImportsRule());
    registry.registerLintRule(ExplicitRelativeImportsRule());
  }
}
