import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:siberian_core/siberian_core.dart';

class SystemUiChangingObserver extends NavigatorObserver with Logging {
  final String? tag;
  final bool enableLog;
  final (String?, SystemUiOverlayStyle?) Function(String route) onResolveStyle;

  SystemUiChangingObserver({this.tag, required this.onResolveStyle, this.enableLog = true});

  int? _activeStyle;

  void onRouteChanged(String newRoute) {
    var (String? styleName, SystemUiOverlayStyle? requiredStyle) = onResolveStyle(newRoute);
    int? requiredStyleHash = requiredStyle?.hashCode;
    if (requiredStyleHash == null) {
      if (enableLog) {
        verbose('no need to change', tag: tag);
      }
      return;
    }

    if (_activeStyle == requiredStyleHash) {
      if (enableLog) {
        verbose("required style is same as current", tag: tag);
      }
      return;
    }

    _activeStyle = requiredStyleHash;
    Future.microtask(() => SystemChrome.setSystemUIOverlayStyle(requiredStyle!));
    if (enableLog) {
      verbose("switching UI style to '${styleName ?? requiredStyle.hashCode}'", tag: tag);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute?.settings.name?.isNotEmpty == true) {
      onRouteChanged(previousRoute?.settings.name ?? '');
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name?.isNotEmpty == true) {
      onRouteChanged(route.settings.name ?? '');
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (previousRoute?.settings.name?.isNotEmpty == true) {
      onRouteChanged(previousRoute?.settings.name ?? '');
    }
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute?.settings.name?.isNotEmpty == true) {
      onRouteChanged(oldRoute?.settings.name ?? '');
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
