import 'package:flutter/foundation.dart';

import 'lib/custom_theme.dart';

export 'lib/custom_theme.dart';
export 'lib/theme_builder.dart';

class Theming {
  Theming._();

  static ValueListenable<CustomTheme> get themes => _themes;

  static late final ValueNotifier<CustomTheme> _themes;

  static void initWith(CustomTheme theme) => _themes = ValueNotifier(theme);

  void switchTo(CustomTheme theme) => _themes.value = theme;
}
