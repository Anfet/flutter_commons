import 'package:flutter/material.dart';

import '../randomizer.dart';

Color get randomColor => Color(0xff000000 + randomizer.nextInt(0x00ffffff)).withAlpha(255);

Color get randomLightColor => Color(0xff808080 + randomizer.nextInt(0x00808080)).withAlpha(255);

Color get randomSemiTransparentColor => Color(randomizer.nextInt(0x00ffffff)).withAlpha(30);

extension AppColorExt on Color {
  ColorFilter get filter => ColorFilter.mode(this, BlendMode.srcIn);
}
