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

/// Public class MemoryStorage.
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

/// Public class FileStorage.
class FileStorage implements PropertyStorage {
  final Directory parentDirectory;

  FileStorage({
    required this.parentDirectory,
  });

  File _file(String name) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty for a file operation');
    }

    final segments = name.split('/');
    if (segments.any((segment) => segment.isEmpty || segment == '.' || segment == '..') || name.contains('\\') || name.contains(':')) {
      throw ArgumentError.value(name, 'name', 'Must be a relative file name inside parentDirectory');
    }

    final parent = Directory(parentDirectory.path).absolute.path;
    final file = File('$parent${Platform.pathSeparator}$name').absolute.path;
    final parentPrefix = parent.endsWith(Platform.pathSeparator) ? parent : '$parent${Platform.pathSeparator}';
    final comparableParent = Platform.isWindows ? parentPrefix.toLowerCase() : parentPrefix;
    final comparableFile = Platform.isWindows ? file.toLowerCase() : file;
    if (!comparableFile.startsWith(comparableParent)) {
      throw ArgumentError.value(name, 'name', 'Must be inside parentDirectory');
    }
    return File(file);
  }

  @override
  Future<void> delete(String name) async {
    final file = _file(name);
    try {
      await file.delete();
    } on FileSystemException catch (error) {
      if (!_isMissing(error)) {
        rethrow;
      }
    }
  }

  @override
  FutureOr<bool> exists(String name) => name.isEmpty ? false : _file(name).exists();

  @override
  Future<void> flush() async {}

  @override
  Future<String> get(String name) async {
    if (name.isEmpty) {
      return '';
    }
    final file = _file(name);
    return file.readAsString();
  }

  @override
  Future<void> set(String name, String value) async {
    final file = _file(name);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    try {
      await parentDirectory.delete(recursive: true);
    } on FileSystemException catch (error) {
      if (!_isMissing(error)) {
        rethrow;
      }
    }
    await parentDirectory.create(recursive: true);
  }

  bool _isMissing(FileSystemException error) => error.osError?.errorCode == 2 || error.osError?.errorCode == 3;
}
