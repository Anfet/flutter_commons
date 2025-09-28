import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

AppBuildVariant _appConfigVariant = AppBuildVariant.developer;

AppBuildVariant get appConfigVariant => _appConfigVariant;

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
      _appConfigVariant = AppBuildVariant.values.byName(text);
    } else if (const bool.hasEnvironment('CONFIG_VARIANT')) {
      var text = const String.fromEnvironment('CONFIG_VARIANT', defaultValue: _defaultVariant);
      _appConfigVariant = AppBuildVariant.values.byName(text);
    } else {
      _appConfigVariant = kDebugMode ? AppBuildVariant.developer : AppBuildVariant.release;
    }

    logMessage(_appConfigVariant.name, tag: 'AppBuildVariant');
  }

  static bool get isRelease => _appConfigVariant == AppBuildVariant.release;

  static bool get isDev => _appConfigVariant == AppBuildVariant.developer;

  static bool get isInternal => _appConfigVariant == AppBuildVariant.internal;
}
