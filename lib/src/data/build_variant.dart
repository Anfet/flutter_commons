import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

BuildVariant get buildVariant => _buildVariant;
BuildVariant _buildVariant = BuildVariant.developer;

bool get isRelease => buildVariant == BuildVariant.release;

bool get isDev => buildVariant == BuildVariant.developer;

bool get isInternal => buildVariant == BuildVariant.internal;

enum BuildVariant {
  developer(20),
  internal(10),
  release(0),
  ;

  final int level;

  const BuildVariant(this.level);

  static const _propName = 'BUILD_VARIANT';
  static const _defaultVariant = 'release';

  static void loadFromEnviroment() {
    if (const bool.hasEnvironment(_propName)) {
      var text = const String.fromEnvironment(_propName, defaultValue: _defaultVariant);
      _buildVariant = BuildVariant.values.byName(text);
    } else {
      _buildVariant = kDebugMode ? BuildVariant.developer : BuildVariant.release;
    }

    logMessage('Build Variant = $buildVariant', level: Level.info, tag: 'BuildVariant');
  }
}
