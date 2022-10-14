import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

import '../extensions/any_ext.dart';
import 'navigation_result.dart';

class GlobalNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey(debugLabel: "GlobalNavigator");

  static NavigatorState get _navigator => key.currentState!;

  static FutureOr pop({NavigationResult? result}) {
    GlobalLogger.instance.logMessage("popping $result", tag: _tag);
    return _navigator.canPop().let((it) => it ? _navigator.pop(result) : SystemNavigator.pop());
  }

  static popCancel({dynamic data}) => pop(result: NavigationResult.cancel(data));

  static replaceNamed(String name, {dynamic data}) {
    GlobalLogger.instance.logMessage("replacing route to $name($data)", tag: _tag);
    return _navigator.pushReplacementNamed(name, arguments: data);
  }

  static pushNamed(String name, {dynamic data}) {
    GlobalLogger.instance.logMessage("replacing route to $name($data)", tag: _tag);
    return _navigator.pushNamed(name, arguments: data);
  }

  static popToAndReturn(String popTo, NavigationResult? navigationResult) async {
    GlobalLogger.instance.logMessage("popping to $popTo", tag: _tag);
    _navigator.popUntil((route) => route.settings.name == popTo);
    return pop(result: navigationResult);
  }

  static Future pushNamedAndRemoveUntil(String newRouteName, bool Function(Route route) test, {dynamic data}) =>
      _navigator.pushNamedAndRemoveUntil(newRouteName, test, arguments: data);

  static Future push(Route route) => _navigator.push(route);

  static Future replace(Route route) => _navigator.pushReplacement(route);

  static void popDialog(BuildContext context) => Navigator.of(context).pop();
}

const _tag = "GlobalNavigator";
