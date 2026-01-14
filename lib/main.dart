import 'package:analysis_server_plugin/plugin.dart' show Plugin;
import 'package:analysis_server_plugin/registry.dart' show PluginRegistry;
import 'src/explicit_imports.dart' show ExplicitImportsRule;

final plugin = ExplicitImportsPlugin();

class ExplicitImportsPlugin extends Plugin {
  @override
  String get name => 'Explicit imports plugin';

  @override
  void register(PluginRegistry registry) {
    // Register diagnostics, quick fixes, and assists.
    registry.registerWarningRule(ExplicitImportsRule());
  }
}
