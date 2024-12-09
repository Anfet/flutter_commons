import 'dart:math';

import 'package:flutter/widgets.dart';

extension NumberExt on num {
  String get asSigned => this > 0 ? "+$this" : "$this";

  bool get isZero => abs() < 0.00001;

  bool between(num a, num b) => this > a && this < b;
}

extension IntExt on int {
  bool toBool() => this != 0;

  int get kb => this * 1024;

  int get mb => kb * 1024;
}

extension DoubleExt on double {
  bool get isInt => (this - floor()).abs() < 0.00001;

  int? get asIntOrNull => isInt ? floor() : null;

  double truncFraction([int digits = 1]) {
    var divider = pow(10, digits);
    var result = (this * divider).truncate() / divider;
    return result;
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

  static double calculateEnteredQuantity(TextEditingController controller, {int maxLength = 8, int maxFraction = 2}) {
    var amount = (double.tryParse(controller.text.replaceAll(',', '.')) ?? 0);
    var truncated = amount.truncFraction(maxFraction).abs();

    var fraction = truncated.fraction;
    var i = truncated.toInt();
    if ('$i'.length > maxLength) {
      truncated = (truncated / 10);
      truncated = truncated.truncateToDouble() + fraction;
    }

    if ('$amount' != '$truncated' || amount.fraction > truncated.fraction || controller.text.length > '$amount'.length) {
      var fractionLimit = pow(1, -(maxFraction + 1));
      controller.text = '${truncated.fraction < fractionLimit ? truncated.toInt() : truncated}';
    }

    return truncated;
  }
}
