export 'storable_property.dart';
export 'revertable_property.dart';
export 'listenable_property.dart';
export 'enum_property.dart';

import 'dart:async';
import 'dart:io';

abstract interface class PropertyStorage {
  FutureOr<String> get(String name);

  Future<void> set(String name, String value);

  FutureOr<bool> exists(String name);

  Future<void> flush();

  Future<void> delete(String name);

  Future<void> clear();
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

  @override
  Future<void> clear() async {
    values.clear();
  }
}

class FileStorage implements PropertyStorage {
  final Directory parentDirectory;

  FileStorage({
    required this.parentDirectory,
  });

  @override
  Future<void> delete(String name) async {
    await File('${parentDirectory.path}/$name').delete();
  }

  @override
  FutureOr<bool> exists(String name) => File('${parentDirectory.path}/$name').exists();

  @override
  Future<void> flush() async {}

  @override
  FutureOr<String> get(String name) => File('${parentDirectory.path}/$name').readAsString();

  @override
  Future<void> set(String name, String value) => File('${parentDirectory.path}/$name').writeAsString(value, flush: true);

  @override
  Future<void> clear() async {
    try {
      await parentDirectory.delete(recursive: true);
    } catch (_) {
      //mute
    }
  }
}
