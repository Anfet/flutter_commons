import 'dart:async';

import 'package:siberian_core/src/utils.dart';

import 'property_storage.dart';

class MemoryProperty<T> implements Property<T> {
  T _value;

  final T? _deletedValue;

  MemoryProperty(this._value, [this._deletedValue]);

  @override
  T get cachedValue => _value;

  @override
  FutureOr<void> delete() {
    if (_deletedValue != null) {
      _value = require(_deletedValue);
    }
  }

  @override
  FutureOr<T> getValue() => cachedValue;

  @override
  FutureOr<void> setValue(T val) => _value = val;
}
