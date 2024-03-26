import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:siberian_core/siberian_core.dart';

class LazyProperty<T> implements Property<T> {
  T _value;
  final AsyncValueGetter<T> getter;

  LazyProperty(
    this._value, {
    required this.getter,
  });

  @override
  T get cachedValue => _value;

  @override
  FutureOr<void> delete() {
    throw UnsupportedError('delete not supported for LazyProperty');
  }

  @override
  FutureOr<T> getValue() async {
    _value = await getter();
    return _value;
  }

  @override
  FutureOr<void> setValue(T val) {
    _value = val;
  }
}
