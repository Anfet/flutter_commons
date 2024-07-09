import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

class Lazy<T> {
  T? instance;
  final ValueGetter<T> initializer;

  Lazy(this.initializer);

  T call() {
    instance ??= initializer();
    return require(instance);
  }
}
