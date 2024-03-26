import 'dart:async';

import 'package:siberian_core/siberian_core.dart';

class RevertableProperty<T> implements Property<T> {
  T? _initialValue;
  final Property<T> child;

  RevertableProperty(this.child);

  bool get hasChanged => _initialValue != cachedValue;

  @override
  FutureOr<T> getValue() async {
    final value = await child.getValue();
    _initialValue ??= value;
    return value;
  }

  @override
  T get cachedValue => child.cachedValue;

  @override
  FutureOr<void> delete() => child.delete();

  @override
  FutureOr<void> setValue(T val) => child.setValue(val);

  FutureOr<void> revert() async {
    if (_initialValue == null || !hasChanged) {
      return;
    }

    await setValue(require(_initialValue));
  }

  RevertableProperty<T> reset() {
    _initialValue = null;
    return this;
  }
}
