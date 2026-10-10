import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes/add_event_handlers.dart';
import 'src/rules/bloc_missing_on_init.dart';
import 'src/rules/bloc_unhandled_event.dart';
import 'src/rules/bloc_widget_without_init_event.dart';
import 'src/rules/waitable_complete_without_result.dart';
import 'src/rules/waitable_event_not_completed.dart';

/// Entry point loaded by the Dart analysis server.
final plugin = FlutterCommonsLintsPlugin();

/// Bloc and `WaitableEvent` rules for projects built on `flutter_commons`.
///
/// Every rule is a warning, so it is enabled once the plugin is listed in
/// `analysis_options.yaml`.
class FlutterCommonsLintsPlugin extends Plugin {
  @override
  String get name => 'flutter_commons_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(BlocMissingOnInit())
      ..registerWarningRule(BlocWidgetWithoutInitEvent())
      ..registerWarningRule(BlocUnhandledEvent())
      ..registerWarningRule(WaitableCompleteWithoutResult())
      ..registerWarningRule(WaitableEventNotCompleted())
      ..registerFixForRule(BlocMissingOnInit.code, AddOnInitHandler.new)
      ..registerFixForRule(BlocUnhandledEvent.code, AddUnhandledEventHandlers.new);
  }
}
