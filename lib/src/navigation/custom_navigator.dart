import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_core/src/navigation/navigation_arguments.dart';

abstract class CustomNavigator with Logging {
  final GlobalKey<NavigatorState> key;
  final List<RouteSettings> stack = [];

  CustomNavigator(String debugLabel) : key = GlobalKey(debugLabel: debugLabel);

  NavigatorState get _navigator => key.currentState!;

  String get currentPath {
    String? path;
    key.currentState?.popUntil((route) {
      path = route.settings.name;
      return true;
    });

    return path ?? "";
  }

  List<String> get currentSplitPath {
    List<String> paths = [];
    key.currentState?.popUntil((route) {
      paths.add(route.settings.name ?? "");
      return true;
    });

    return paths;
  }

  FutureOr pop([NavigationResult? result]) {
    logMessage("popping $result");
    if (_navigator.canPop()) {
      _navigator.pop(result);
      stack.removeLast();
    } else {
      SystemNavigator.pop();
    }
  }

  FutureOr popCancel([dynamic data]) => pop(NavigationResult.cancel(data));

  Future replaceNamed(String name, {dynamic data}) {
    logMessage("replacing route to '$name' {$data}");
    NavigationArguments? arguments = data?.let((it) => it is NavigationArguments ? it : NavigationArguments(it));
    return _navigator.pushReplacementNamed(name, arguments: arguments);
  }

  Future<dynamic> pushNamed(String name, {data}) {
    logMessage("replacing route to '$name' {$data}");
    NavigationArguments? arguments = data?.let((it) => it is NavigationArguments ? it : NavigationArguments(it));
    stack.clear();
    stack.add(RouteSettings(name: name, arguments: arguments));
    return _navigator.pushNamed(name, arguments: arguments);
  }

  popToAndReturn(String popTo, NavigationResult? navigationResult) async {
    logMessage("popping to '$popTo' with result {$navigationResult}");
    _navigator.popUntil((route) {
      var untilMatched = route.settings.name == popTo;
      if (!untilMatched) {
        stack.removeLast();
      }
      return untilMatched;
    });

    stack.removeLast();
    return pop(navigationResult);
  }

  Future pushNamedAndRemoveUntil(String newRouteName, bool Function(Route route) test, {data}) {
    logMessage("pushing '$newRouteName' with arguments {$data}} and popping to 'unknown'");
    NavigationArguments? arguments = data?.let((it) => it is NavigationArguments ? it : NavigationArguments(it));
    return _navigator.pushNamedAndRemoveUntil(newRouteName, test, arguments: arguments);
  }

  Future push(Route route) async {
    assert(route.settings.arguments == null || route.settings.arguments is! NavigationArguments,
        'route setting must be NavigationData');
    logMessage("pushing '${route.settings.name}' with arguments {${route.settings.arguments}}");
    stack.add(RouteSettings(name: route.settings.name, arguments: route.settings.arguments));
    return _navigator.push(route);
  }

  Future replace(Route route) {
    assert(route.settings.arguments == null || route.settings.arguments is! NavigationArguments,
        'route setting must be NavigationData');
    logMessage(
        "replacing current route '$currentPath' to '${route.settings.name}' with arguments {${route.settings.arguments}}");
    stack.clear();
    stack.add(RouteSettings(name: route.settings.name, arguments: route.settings.arguments));
    return _navigator.pushReplacement(route);
  }

  void popDialog(BuildContext context) => Navigator.of(context).pop();
}
