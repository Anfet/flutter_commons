import 'package:flutter/material.dart';
import 'package:flutter_logger/flutter_logger.dart';

class LoggingNavigatorObserver extends NavigatorObserver with Logging {
  final String? tag;

  LoggingNavigatorObserver({this.tag});

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      trace("'${route.settings.name}' pop", tag: tag);
    } else {
      Future.sync(() => route.popped).then((poppedResult) {
        trace("'${route.settings.name}' return ($poppedResult) to '${previousRoute.settings.name}'", tag: tag);
      });
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    trace("push '${route.settings.name}'(${route.settings.arguments ?? ''})", tag: tag);
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (previousRoute == null) {
      trace("remove '${route.settings.name}'", tag: tag);
    } else {
      trace("remove '${route.settings.name}' and return to '${previousRoute.settings.name}'", tag: tag);
    }
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    trace("remove '{${oldRoute?.settings.name}' and push '${newRoute?.settings.name}'(${newRoute?.settings.arguments ?? ''})", tag: tag);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
