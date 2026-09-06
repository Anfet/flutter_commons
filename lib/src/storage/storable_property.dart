import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../logging.dart';
import 'storage.dart';

/// Public abstract class StorableProperty.
abstract class StorableProperty<T> {
  T get cachedValue;

  FutureOr<T> getValue();

  Future<void> setValue(T val);

  Future<void> delete();

  FutureOr<bool> exists();
}

/// Public abstract class StorablePropertyImpl.
abstract class StorablePropertyImpl<T> implements StorableProperty<T> {
  final PropertyStorage storage;
  final String name;
  final ValueSetter<T>? onSave;
  final T Function()? _defaultValue;

  late T _cachedValue;

  @override
  T get cachedValue => _cachedValue;

  StorablePropertyImpl(
    this.storage,
    this.name, {
    this.onSave,
    T Function()? defaultValue,
  }) : _defaultValue = defaultValue {
    if (_defaultValue != null) {
      _cachedValue = _defaultValue();
    }
  }

  @override
  Future<void> delete() async {
    await storage.delete(name);
    final defaultValue = _defaultValue;
    if (defaultValue == null) {
      await getValue();
    } else {
      _cachedValue = defaultValue();
    }
  }

  @override
  Future<T> getValue() async {
    final defaultValue = _defaultValue;
    if (!await storage.exists(name)) {
      if (defaultValue == null) {
        throw UnsupportedError('A legacy StorablePropertyImpl subclass must override getValue().');
      }
      _cachedValue = defaultValue();
      return cachedValue;
    }

    // Storage failures are not malformed values and must remain observable.
    final rawValue = await storage.get(name);
    try {
      _cachedValue = decode(rawValue);
    } catch (error) {
      if (defaultValue == null) {
        rethrow;
      }
      _cachedValue = defaultValue();
      // Decoder errors may contain the entire stored value, including secrets.
      logMessage('Invalid stored value for $runtimeType; using default (${error.runtimeType}).', tag: 'storage');
      await _repairInvalidValue();
    }
    return cachedValue;
  }

  Future<void> _repairInvalidValue() async {}

  @override
  Future<void> setValue(T val) async {
    await storage.set(name, encode(val));
    if (_defaultValue != null) {
      _cachedValue = val;
    }
    onSave?.call(val);
  }

  T decode(String value) => value as T;

  String encode(T value) => '$value';

  @override
  String toString() => '$cachedValue';

  @override
  FutureOr<bool> exists() => storage.exists(name);
}

final class BoolProperty extends StorablePropertyImpl<bool> {
  final bool defaultValue;

  BoolProperty(super.storage, super.name, {super.onSave, this.defaultValue = false}) : super(defaultValue: () => defaultValue);

  @override
  bool decode(String value) => switch (value) {
    'true' => true,
    'false' => false,
    _ => throw FormatException('Invalid boolean value for "$name"'),
  };

  @override
  String encode(bool value) => '$value';
}

final class IntProperty extends StorablePropertyImpl<int> {
  final int defaultValue;

  IntProperty(super.storage, super.name, {super.onSave, this.defaultValue = 0}) : super(defaultValue: () => defaultValue);

  @override
  int decode(String value) => int.parse(value);

  @override
  String encode(int value) => '$value';
}

final class DoubleProperty extends StorablePropertyImpl<double> {
  final double defaultValue;

  DoubleProperty(super.storage, super.name, {super.onSave, this.defaultValue = 0}) : super(defaultValue: () => defaultValue);

  @override
  double decode(String value) => double.parse(value);

  @override
  String encode(double value) => '$value';
}

final class StringProperty extends StorablePropertyImpl<String> {
  final String defaultValue;

  StringProperty(super.storage, super.name, {super.onSave, this.defaultValue = ''}) : super(defaultValue: () => defaultValue);

  @override
  String decode(String value) => value;

  @override
  String encode(String value) => value;
}

/// Public class JsonProperty.
class JsonProperty<T> extends StorablePropertyImpl<T> {
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
  }) : super(defaultValue: ifNotExist);

  // Preserve the legacy JSON recovery contract without emitting an onSave event.
  @override
  Future<void> _repairInvalidValue() => storage.set(name, encode(cachedValue));

  @override
  T decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON object for "$name"');
    }
    return fromJson(decoded);
  }

  @override
  String encode(T value) => jsonEncode(toJson(value));
}

/// Public class DateTimeProperty.
class DateTimeProperty extends StorablePropertyImpl<DateTime> {
  DateTimeProperty(super.storage, super.name, {super.onSave}) : super(defaultValue: () => DateTime(0));

  @override
  DateTime decode(String value) => DateTime.parse(value).toLocal();

  @override
  String encode(DateTime value) => value.toUtc().toString();
}
