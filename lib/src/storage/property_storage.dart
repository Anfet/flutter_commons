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
}



