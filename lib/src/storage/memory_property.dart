import 'dart:async';

import 'package:siberian_core/siberian_core.dart';

class MemoryProperty<T> implements Property<T> {
  T _value;

  MemoryProperty(this._value);

  @override
  T get cachedValue => _value;

  @override
  FutureOr<void> delete() {}

  @override
  FutureOr<T> getValue() => cachedValue;

  @override
  Future<void> setValue(T val) async {
    _value = val;
  }
}
