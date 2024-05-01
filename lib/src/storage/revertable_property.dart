import 'dart:async';

import 'package:siberian_core/siberian_core.dart';

class RevertableProperty<T> implements Property<T> {
  T? _value;

  final Property<T> child;

  RevertableProperty(this.child) : _value = child.cachedValue;

  bool get hasChanged => _value != cachedValue;

  @override
  FutureOr<T> getValue() async {
    _value = await child.getValue();
    return require(_value);
  }

  @override
  T get cachedValue => require(_value);

  @override
  FutureOr<void> delete() => reset();

  @override
  FutureOr<void> setValue(T val) => _value = val;

  FutureOr<void> revert() => _value = child.cachedValue;

  FutureOr<void> reset() => _value = child.cachedValue;

  FutureOr<void> commit() => child.setValue(require(_value));
}
