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

  static double calculateEnteredQuantity(
    TextEditingController controller, {
    int maxLength = 8,
    int maxFraction = 2,
    TypedResultCallback<String, String>? onFormat,
  }) {
    var amount = (double.tryParse(controller.text.replaceAll(',', '.').replaceAll(' ', '')) ?? 0);
    var truncated = amount.truncFraction(maxFraction).abs();

    var i = truncated.toInt();
    var len = '$i'.length;
    if (len > maxLength) {
      truncated = double.parse('$i'.substring(0, maxLength));
    }

    if (maxFraction == 0) {
      truncated = truncated.truncateToDouble();
    }

    if ('$amount' != '$truncated' || amount.fraction > truncated.fraction || controller.text.length > '$amount'.length) {
      var fractionLimit = pow(1, -(maxFraction + 1));
      var text = '${truncated.fraction < fractionLimit ? truncated.toInt() : truncated}';
      var formatted = onFormat?.call(text) ?? text;
      controller.text = formatted;
      controller.selection = TextSelection.collapsed(offset: formatted.length);
    }

    return truncated;
  }
}
