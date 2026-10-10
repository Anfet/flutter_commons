import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

extension NumberExt on num {
  String get asSigned => this > 0 ? "+$this" : "$this";

  bool get isZero => abs() < 0.00001;

  bool between(num a, num b) => this > a && this < b;
}

extension IntExt on int {
  bool toBool() => this != 0;

  int get kb => this * 1024;

  int get mb => kb * 1024;

  int get descending => this * -1;

  int get desc => descending;
}

extension DoubleExt on double {
  bool get isInt => isFinite && (this - roundToDouble()).abs() < 0.00001;

  int? get asIntOrNull => isInt ? round() : null;

  double truncFraction([int digits = 1]) {
    final divider = pow(10, digits);
    final scaled = this * divider;
    // Snap values a float error left just below an integer (0.29 * 100 = 28.999...).
    final nearest = scaled.roundToDouble();
    final whole = (scaled - nearest).abs() < 1e-9 * max(1, scaled.abs()) ? nearest : scaled.truncateToDouble();
    return whole / divider;
  }

  double get fraction {
    return this - floor();
  }

  double get asRadians {
    return this * pi / 180;
  }
}

sealed class NumericUtils {
  NumericUtils._();

  static double calculateEnteredQuantity(
    TextEditingController controller, {
    int maxLength = 8,
    int maxFraction = 2,
    TypedResultCallback<String, String>? onFormat,
  }) {
    if (maxLength < 1) {
      throw ArgumentError.value(maxLength, 'maxLength', 'Must be at least 1');
    }
    if (maxFraction < 0) {
      throw ArgumentError.value(maxFraction, 'maxFraction', 'Must be non-negative');
    }

    final amount = double.tryParse(controller.text.replaceAll(',', '.').replaceAll(' ', '')) ?? 0;
    var truncated = amount.truncFraction(maxFraction).abs();

    final i = truncated.toInt();
    final len = '$i'.length;
    if (len > maxLength) {
      truncated = double.parse('$i'.substring(0, maxLength));
    }

    if (maxFraction == 0) {
      truncated = truncated.truncateToDouble();
    }

    final fractionLimit = pow(10, -(maxFraction + 1));
    final text = '${truncated.fraction < fractionLimit ? truncated.toInt() : truncated}';
    if (controller.text != text) {
      var formatted = onFormat?.call(text) ?? text;
      controller.text = formatted;
      controller.selection = TextSelection.collapsed(offset: formatted.length);
    }

    return truncated;
  }
}
