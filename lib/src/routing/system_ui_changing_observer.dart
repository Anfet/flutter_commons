import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:siberian_core/siberian_core.dart';

typedef SystemUiOverlayStyleResolver = (String?, SystemUiOverlayStyle?) Function(String route);

class SystemUiChangingObserver extends NavigatorObserver with Logging {
  final String? tag;
  final bool enableLog;
  final Duration? delay;
  final SystemUiOverlayStyleResolver onResolveStyle;

  SystemUiChangingObserver({this.tag, required this.onResolveStyle, this.enableLog = true, this.delay});

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

    Future.delayed(delay ?? const Duration(milliseconds: 300)).then((value) {
      _activeStyle = requiredStyleHash;
      SystemChrome.setSystemUIOverlayStyle(requiredStyle!);
      if (enableLog) {
        verbose("switching UI style to '${styleName ?? requiredStyle.hashCode}'", tag: tag);
      }
    });
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
