import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class EnumProperty<T extends Enum> extends StorablePropertyImpl<T> {
  late T _cachedValue;
  final T defaultValue;
  final Iterable<T> values;

  EnumProperty(super.storage, super.name, {required this.values, super.onSave, required this.defaultValue}) : _cachedValue = defaultValue;

  @override
  T get cachedValue => _cachedValue;

  @override
  FutureOr<T> getValue() async {
    if (await storage.exists(name)) {
      var string = await storage.get(name);
      _cachedValue = values.byNameOr(string, defaultValue);
    } else {
      _cachedValue = defaultValue;
    }
    return cachedValue;
  }

  @override
  Future<void> setValue(T val) async {
    await storage.set(name, val.name);
    _cachedValue = val;
    onSave?.call(val);
  }
}
