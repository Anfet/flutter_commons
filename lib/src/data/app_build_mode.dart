import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

AppBuildMode get appBuildMode => _appBuildMode;
AppBuildMode _appBuildMode = AppBuildMode.developer;

bool get isRelease => appBuildMode == AppBuildMode.release;

bool get isDev => appBuildMode == AppBuildMode.developer;

bool get isInternal => appBuildMode == AppBuildMode.internal;

enum AppBuildMode {
  developer(20),
  internal(10),
  release(0),
  ;

  final int level;

  const AppBuildMode(this.level);

  static const buildModeName = 'BUILD_MODE';
  static const defaultVariant = 'release';

  static void loadFromEnviroment() {
    if (const bool.hasEnvironment(buildModeName)) {
      var text = const String.fromEnvironment(buildModeName, defaultValue: defaultVariant);
      _appBuildMode = AppBuildMode.values.byName(text);
    } else {
      _appBuildMode = kDebugMode ? AppBuildMode.developer : AppBuildMode.release;
    }

    logMessage('Build mode = $appBuildMode', level: Level.info, tag: 'BuildMode');
  }
}
