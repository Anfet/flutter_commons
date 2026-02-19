import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class RevertableProperty<T> implements StorableProperty<T> {
  T? _value;

  T _initialValue;

  final StorableProperty<T> child;

  RevertableProperty(this.child)
      : _value = child.cachedValue,
        _initialValue = child.cachedValue;

  bool get hasChanged => _value != _initialValue;

  @override
  FutureOr<T> getValue() async {
    _value = await child.getValue();
    return require(_value);
  }

  @override
  T get cachedValue => _value ?? _initialValue;

  @override
  Future<void> delete() async {
    _value = null;
  }

  @override
  Future<void> setValue(T val) async {
    _value = val;
  }

  FutureOr<void> revert() => _value = _initialValue;

  FutureOr<void> commit() async {
    if (_value == null) {
      await child.delete();
    } else {
      await child.setValue(require(_value));
    }

    _initialValue = await getValue();
  }

  @override
  FutureOr<bool> exists() => child.exists();
}
