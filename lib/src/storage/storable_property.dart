import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_logger/flutter_logger.dart';

import 'storage.dart';

abstract class StorableProperty<T> {
  T get cachedValue;

  FutureOr<T> getValue();

  Future<void> setValue(T val);

  Future<void> delete();

  FutureOr<bool> exists();
}

abstract class StorablePropertyImpl<T> implements StorableProperty<T> {
  final PropertyStorage storage;
  final String name;
  final ValueSetter<T>? onSave;

  @override
  T get cachedValue;

  StorablePropertyImpl(
    this.storage,
    this.name, {
    this.onSave,
  });

  @override
  Future<void> delete() async {
    await storage.delete(name);
    await getValue();
  }

  @override
  Future<void> setValue(T val) async {
    await storage.set(name, '$val');
    onSave?.call(val);
  }

  @override
  String toString() => '$cachedValue';

  @override
  FutureOr<bool> exists() => storage.exists(name);
}

final class BoolProperty extends StorablePropertyImpl<bool> {
  late bool _cachedValue;
  final bool defaultValue;

  @override
  bool get cachedValue => _cachedValue;

  BoolProperty(super.storage, super.name, {super.onSave, this.defaultValue = false}) : _cachedValue = defaultValue;

  @override
  FutureOr<bool> getValue() async {
    if (await exists()) {
      _cachedValue = bool.tryParse(await storage.get(name)) ?? false;
    } else {
      _cachedValue = defaultValue;
    }
    return cachedValue;
  }

  @override
  Future<void> setValue(bool val) async {
    await super.setValue(val);
    _cachedValue = val;
  }
}

final class IntProperty extends StorablePropertyImpl<int> {
  @override
  int get cachedValue => _cachedValue;
  late int _cachedValue;
  final int defaultValue;

  IntProperty(super.storage, super.name, {super.onSave, this.defaultValue = 0}) : _cachedValue = defaultValue;

  @override
  FutureOr<int> getValue() async {
    if (await storage.exists(name)) {
      _cachedValue = int.tryParse(await storage.get(name)) ?? 0;
    } else {
      _cachedValue = defaultValue;
    }
    return cachedValue;
  }

  @override
  Future<void> setValue(int val) async {
    await super.setValue(val);
    _cachedValue = val;
  }
}

final class DoubleProperty extends StorablePropertyImpl<double> {
  @override
  double get cachedValue => _cachedValue;
  late double _cachedValue;
  final double defaultValue;

  DoubleProperty(super.storage, super.name, {super.onSave, this.defaultValue = 0}) : _cachedValue = defaultValue;

  @override
  FutureOr<double> getValue() async {
    if (await storage.exists(name)) {
      _cachedValue = double.tryParse(await storage.get(name)) ?? 0.0;
    } else {
      _cachedValue = defaultValue;
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(double val) async {
    await super.setValue(val);
    _cachedValue = val;
  }
}

final class StringProperty extends StorablePropertyImpl<String> {
  @override
  String get cachedValue => _cachedValue;
  late String _cachedValue;
  final String defaultValue;

  StringProperty(super.storage, super.name, {super.onSave, this.defaultValue = ''}) : _cachedValue = defaultValue;

  @override
  FutureOr<String> getValue() async {
    if (await storage.exists(name)) {
      _cachedValue = await storage.get(name);
    } else {
      _cachedValue = defaultValue;
    }
    return cachedValue;
  }

  @override
  Future<void> setValue(String val) async {
    await super.setValue(val);
    _cachedValue = val;
  }
}

class JsonProperty<T> extends StorablePropertyImpl<T> with Logging {
  @override
  T get cachedValue => _cachedValue;
  late T _cachedValue;

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
      var text = await storage.get(name);
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
    storage.set(name, text);
    _cachedValue = val;
  }
}

class DateTimeProperty extends StorablePropertyImpl<DateTime> with Logging {
  @override
  late DateTime cachedValue = DateTime(0);

  DateTimeProperty(super.storage, super.name);

  @override
  FutureOr<DateTime> getValue() async {
    try {
      var text = await storage.get(name);
      cachedValue = (DateTime.tryParse(text) ?? DateTime(0)).toLocal();
    } catch (ex, stack) {
      warn("property read error '$name'", error: ex, stack: stack);
    }

    return cachedValue;
  }

  @override
  Future<void> setValue(DateTime val) async {
    var text = val.toUtc().toString();
    storage.set(name, text);
    cachedValue = val;
  }
}
