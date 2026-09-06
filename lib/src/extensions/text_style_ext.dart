import 'package:flutter/painting.dart';

extension TextStyleExt on TextStyle {
  TextStyle bold({double? opticalSize}) => _withWeight(FontWeight.bold, opticalSize);

  TextStyle medium({double? opticalSize}) => _withWeight(FontWeight.w500, opticalSize);

  TextStyle normal({double? opticalSize}) => _withWeight(FontWeight.w400, opticalSize);

  TextStyle thin({double? opticalSize}) => _withWeight(FontWeight.w300, opticalSize);

  TextStyle extraBold({double? opticalSize}) => _withWeight(FontWeight.w800, opticalSize);

  TextStyle w100({double? opticalSize}) => _withWeight(FontWeight.w100, opticalSize);

  TextStyle w200({double? opticalSize}) => _withWeight(FontWeight.w200, opticalSize);

  TextStyle w300({double? opticalSize}) => _withWeight(FontWeight.w300, opticalSize);

  TextStyle w400({double? opticalSize}) => _withWeight(FontWeight.w400, opticalSize);

  TextStyle w500({double? opticalSize}) => _withWeight(FontWeight.w500, opticalSize);

  TextStyle w600({double? opticalSize}) => _withWeight(FontWeight.w600, opticalSize);

  TextStyle w700({double? opticalSize}) => _withWeight(FontWeight.w700, opticalSize);

  TextStyle w800({double? opticalSize}) => _withWeight(FontWeight.w800, opticalSize);

  TextStyle w900({double? opticalSize}) => _withWeight(FontWeight.w900, opticalSize);

  TextStyle _withWeight(FontWeight weight, double? opticalSize) {
    if (opticalSize == null) {
      return copyWith(fontWeight: weight);
    }

    final variations = [
      for (final variation in fontVariations ?? const <FontVariation>[]) variation.axis == 'opsz' ? FontVariation('opsz', opticalSize) : variation,
    ];
    if (!variations.any((variation) => variation.axis == 'opsz')) {
      variations.add(FontVariation('opsz', opticalSize));
    }

    return copyWith(fontWeight: weight, fontVariations: variations);
  }
}
