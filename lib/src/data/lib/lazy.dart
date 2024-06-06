import 'package:flutter/cupertino.dart';
import 'package:siberian_core/siberian_core.dart';

class Lazy<T> {
  T? instance;
  final ValueGetter<T> initializer;

  Lazy(this.initializer);

  T call() {
    instance ??= initializer();
    return require(instance);
  }
}
