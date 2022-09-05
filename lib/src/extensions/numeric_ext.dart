extension IntExt on int {
  String get asSigned => this > 0 ? "+$this" : "$this";

  bool toBool() => this != 0;

  int get KB => this * 1024;

  int get MB => KB * 1024;
}

extension DoubleExt on double {
  bool get isInt => (this - floor()).abs() < 0.00001;

  int? get intQuantity => isInt ? floor() : null;

  bool get isZero => abs() < 0.00001;

  String get asSigned => this > 0 ? "+$this" : "$this";

  bool between(double a, double b) => this > a && this < b;
}
