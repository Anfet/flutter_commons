import 'dart:async';

import 'property_storage.dart';

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
  FutureOr<void> setValue(T val) => _value = val;

}
