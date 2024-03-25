import 'dart:async';

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

  FutureOr<void> setValue(T val);

  FutureOr<void> delete();
}
