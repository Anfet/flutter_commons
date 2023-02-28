import 'dart:math';

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
}
