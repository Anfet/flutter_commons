import 'package:flutter/material.dart';

import '../randomizer.dart';

Color get randomColor => Color(0xff000000 + random.nextInt(0x00ffffff)).withAlpha(255);

Color get randomLightColor => Color.fromARGB(255, 0x80 + random.nextInt(0x80), 0x80 + random.nextInt(0x80), 0x80 + random.nextInt(0x80));

Color get randomSemiTransparentColor => Color(random.nextInt(0x00ffffff)).withAlpha(30);

extension AppColorExt on Color {
  ColorFilter get filter => ColorFilter.mode(this, BlendMode.srcIn);
}
