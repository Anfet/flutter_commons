import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:siberian_core/siberian_core.dart';

class MemoryProperty<T> extends ListenableProperty<T> {
  T _value;

  MemoryProperty(this._value);

  @override
  T get cachedValue => _value;

  @override
  FutureOr<void> delete() {
    notifyListeners();
  }

  @override
  FutureOr<T> getValue() => cachedValue;

  @override
  Future<void> setValue(T val) async {
    _value = val;
    notifyListeners();
  }
}
