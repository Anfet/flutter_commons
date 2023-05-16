import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

class LoggingNavigatorObserver extends NavigatorObserver with Logging {
  final String? tag;

  LoggingNavigatorObserver({this.tag});

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      verbose("'${route.settings.name}' pop", tag: tag);
    } else {
      Future.sync(() => route.popped).then((poppedResult) {
        verbose("'${route.settings.name}' return ($poppedResult) to '${previousRoute.settings.name}'", tag: tag);
      });
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    verbose("push '${route.settings.name}'(${route.settings.arguments ?? ''})", tag: tag);
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      verbose("remove '${route.settings.name}'", tag: tag);
    } else {
      verbose("remove '${route.settings.name}' and return to '${previousRoute.settings.name}'", tag: tag);
    }
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    verbose("remove '{${oldRoute?.settings.name}' and push '${newRoute?.settings.name}'(${newRoute?.settings.arguments ?? ''})", tag: tag);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
