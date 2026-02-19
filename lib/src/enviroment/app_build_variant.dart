import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

AppBuildVariant _appBuildVariant = AppBuildVariant.developer;

AppBuildVariant get appBuildVariant => _appBuildVariant;

enum AppBuildVariant {
  developer(20),
  internal(10),
  release(0),
  ;

  final int level;

  const AppBuildVariant(this.level);

  static const _defaultVariant = 'release';

  static void loadFromEnviroment() {
    if (const bool.hasEnvironment('BUILD_VARIANT')) {
      var text = const String.fromEnvironment('BUILD_VARIANT', defaultValue: _defaultVariant);
      _appBuildVariant = AppBuildVariant.values.byName(text);
    } else if (const bool.hasEnvironment('CONFIG_VARIANT')) {
      var text = const String.fromEnvironment('CONFIG_VARIANT', defaultValue: _defaultVariant);
      _appBuildVariant = AppBuildVariant.values.byName(text);
    } else {
      _appBuildVariant = kDebugMode ? AppBuildVariant.developer : AppBuildVariant.release;
    }

    logMessage(_appBuildVariant.name, tag: 'AppBuildVariant');
  }

  static bool get isRelease => _appBuildVariant == AppBuildVariant.release;

  static bool get isDev => _appBuildVariant == AppBuildVariant.developer;

  static bool get isInternal => _appBuildVariant == AppBuildVariant.internal;
}
