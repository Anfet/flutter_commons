import 'package:flutter/material.dart';
import 'package:siberian_core/siberian_core.dart';

abstract class CustomRouteGenerator {
  Route<dynamic> onGenerateRoute(RouteSettings settings);
}

class ChainingRouteGenerator {
  ChainRouteDescription generate(String path, {Object? originalArguments}) {
    final NavigationChain chain = NavigationChain(path);
    String routeName = chain.route;
    NavigationChain? nextChain = chain.advance();
    NavigationArguments? navigationArguments = NavigationArguments(
      originalArguments,
      navigationPath: nextChain?.path,
      queryParameters: chain.queryParameters,
    ).takeIf((it) => it.isNotEmpty);
    return ChainRouteDescription(routeName, navigationArguments);
  }
}

@immutable
class ChainRouteDescription {
  final String screenRoute;
  final NavigationArguments? arguments;

  const ChainRouteDescription(this.screenRoute, this.arguments);
}
