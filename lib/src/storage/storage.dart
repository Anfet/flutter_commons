export 'storable_property.dart';
export 'revertable_property.dart';
export 'listenable_property.dart';

import 'dart:async';

abstract class PropertyStorage {
  FutureOr<String> get(String name);

  Future<void> set(String name, String value);

  FutureOr<bool> exists(String name);

  Future<void> flush();

  Future<void> delete(String name);
}

class MemoryStorage implements PropertyStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String name) async {
    values.remove(name);
  }

  @override
  FutureOr<bool> exists(String name) => values.containsKey(name) && values[name] != null;

  @override
  Future<void> flush() async {}

  @override
  FutureOr<String> get(String name) {
    return values[name] ?? '';
  }

  @override
  Future<void> set(String name, String value) async {
    values[name] = value;
  }
}
