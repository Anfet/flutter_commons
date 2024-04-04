import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:siberian_logger/siberian_logger.dart';

import 'property_storage.dart';

abstract class StorageProperty<T> implements Property<T> {
  final PropertyStorage _storage;
  final String name;
  final ValueSetter<T>? onSave;

  late T _cachedValue;

  @override
  T get cachedValue => _cachedValue;

  StorageProperty(
    this._storage,
    this.name, {
    this.onSave,
  });

  @override
  Future<void> delete() async {
    await _storage.delete(name);
    await getValue();
  }

  @override
  Future<void> setValue(T val) async {
    await _storage.set(name, '$val');
    _cachedValue = val;
    onSave?.call(val);
  }

  @override
  String toString() => '$cachedValue';
}

final class BoolProperty extends StorageProperty<bool> {
  BoolProperty(super._storage, super.name, {super.onSave}) {
    _cachedValue = false;
  }

  @override
  FutureOr<bool> getValue() async {
    _cachedValue = bool.tryParse(await _storage.get(name)) ?? false;
    return cachedValue;
  }
}

final class IntProperty extends StorageProperty<int> {
  IntProperty(super._storage, super.name, {super.onSave}) {
    _cachedValue = 0;
  }

  @override
  FutureOr<int> getValue() async {
    _cachedValue = int.tryParse(await _storage.get(name)) ?? 0;
    return cachedValue;
  }
}

final class DoubleProperty extends StorageProperty<double> {
  DoubleProperty(super._storage, super.name, {super.onSave}) {
    _cachedValue = 0;
  }

  @override
  FutureOr<double> getValue() async {
    _cachedValue = double.tryParse(await _storage.get(name)) ?? 0.0;
    return cachedValue;
  }
}

final class StringProperty extends StorageProperty<String> {
  StringProperty(super._storage, super.name, {super.onSave}) {
    _cachedValue = '';
  }

  @override
  FutureOr<String> getValue() async {
    _cachedValue = await _storage.get(name);
    return cachedValue;
  }
}

class JsonProperty<T> extends StorageProperty<T> with Logging {
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T data) toJson;
  final T Function() ifNotExist;

  JsonProperty(
    super.storage,
    super.name, {
    super.onSave,
    required this.fromJson,
    required this.toJson,
    required this.ifNotExist,
  }) {
    _cachedValue = ifNotExist();
  }

  @override
  FutureOr<T> getValue() async {
    try {
      var text = await _storage.get(name);
      _cachedValue = fromJson(jsonDecode(text));
    } catch (ex) {
      warn("property read error '$name'", error: ex);
      _cachedValue = ifNotExist();
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(T val) async {
    var text = jsonEncode(toJson(val));
    _storage.set(name, text);
    _cachedValue = val;
  }
}

class DateTimeProperty extends StorageProperty<DateTime> with Logging {
  @override
  late DateTime cachedValue = DateTime(0);

  DateTimeProperty(super._storage, super.name);

  @override
  FutureOr<DateTime> getValue() async {
    try {
      var text = await _storage.get(name);
      cachedValue = (DateTime.tryParse(text) ?? DateTime(0)).toLocal();
    } catch (ex, stack) {
      warn("property read error '$name'", error: ex, stack: stack);
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(DateTime val) async {
    var text = val.toUtc().toString();
    _storage.set(name, text);
    cachedValue = val;
  }
}
