import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:siberian_core/siberian_core.dart';

abstract class PropertyStorage {
  FutureOr<String> get(String name);

  Future<void> set(String name, String value);

  FutureOr<bool> exists(String name);

  Future<void> flush();

  Future<void> delete(String name);
}

abstract interface class Property<T> {
  T get cachedValue;

  FutureOr<T> getValue();

  Future<void> setValue(T val);

  FutureOr<void> delete();

  FutureOr<bool> isSet();
}

abstract class StorageProperty<T> implements Property<T> {
  final PropertyStorage _storage;
  final String name;
  final ValueSetter<T>? onSave;

  StorageProperty(
    this._storage,
    this.name, {
    this.onSave,
  });

  @override
  Future<void> delete() => _storage.delete(name);

  @override
  Future<void> setValue(T val) async {
    await _storage.set(name, '$val');
    onSave?.call(val);
  }

  @override
  String toString() => '$cachedValue';

  @override
  FutureOr<bool> isSet() => _storage.exists(name);
}

final class BoolProperty extends StorageProperty<bool> {
  BoolProperty(super._storage, super.name, {super.onSave});

  @override
  bool cachedValue = false;

  @override
  FutureOr<bool> getValue() async {
    cachedValue = bool.tryParse(await _storage.get(name)) ?? false;
    return cachedValue;
  }
}

final class IntProperty extends StorageProperty<int> {
  IntProperty(super._storage, super.name, {super.onSave});

  @override
  int cachedValue = 0;

  @override
  FutureOr<int> getValue() async {
    cachedValue = int.tryParse(await _storage.get(name)) ?? 0;
    return cachedValue;
  }
}

final class DoubleProperty extends StorageProperty<double> {
  DoubleProperty(super._storage, super.name, {super.onSave});

  @override
  double cachedValue = 0;

  @override
  FutureOr<double> getValue() async {
    cachedValue = double.tryParse(await _storage.get(name)) ?? 0.0;
    return cachedValue;
  }
}

final class StringProperty extends StorageProperty<String> {
  StringProperty(super._storage, super.name, {super.onSave});

  @override
  String cachedValue = '';

  @override
  FutureOr<String> getValue() async {
    cachedValue = await _storage.get(name);
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
  });

  @override
  late T cachedValue = ifNotExist();

  @override
  FutureOr<T> getValue() async {
    try {
      var text = await _storage.get(name);
      cachedValue = fromJson(jsonDecode(text));
    } catch (ex) {
      warn("property read error '$name'", error: ex);
      cachedValue = ifNotExist();
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(T val) async {
    var text = jsonEncode(toJson(val));
    _storage.set(name, text);
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
      warn("property read error '$name'", error: ex, stackTrace: stack);
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(DateTime val) async {
    var text = val.toUtc().toString();
    _storage.set(name, text);
  }
}
