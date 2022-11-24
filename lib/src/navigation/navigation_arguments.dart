import 'package:flutter/foundation.dart';

@immutable
class NavigationArguments {
  final Object? passedArguments;
  final String? navigationPath;
  final Map<String, Object?>? queryParameters;

  bool get isEmpty => passedArguments == null && navigationPath == null && (queryParameters?.isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;

  const NavigationArguments(this.passedArguments, {this.navigationPath, this.queryParameters});

  const NavigationArguments.empty()
      : passedArguments = null,
        navigationPath = null,
        queryParameters = null;

  @override
  String toString() {
    return 'NavigationArguments{passedArguments: $passedArguments, navigationPath: $navigationPath, queryParameters: $queryParameters}';
  }
}
