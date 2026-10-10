export 'storable_property.dart';
export 'revertable_property.dart';
export 'listenable_property.dart';
export 'enum_property.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';

abstract interface class PropertyStorage {
  /// Returns the stored value. Defined only when [exists] is `true`: for a missing name [MemoryStorage] returns an
  /// empty string and [FileStorage] throws a [FileSystemException].
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
///
/// Each value is a file under [parentDirectory]. [set] writes a temporary file next to the target and renames it over
/// the target, so an interrupted write leaves the previous value intact. Names ending with [_tempSuffix] are reserved.
class FileStorage implements PropertyStorage {
  static const _tempSuffix = '.fc-tmp';
  static final _random = Random();

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
    if (name.endsWith(_tempSuffix)) {
      throw ArgumentError.value(name, 'name', 'Must not end with $_tempSuffix, it is reserved for temporary files');
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
    final temp = File('${file.path}.${_random.nextInt(1 << 32).toRadixString(36)}$_tempSuffix');
    try {
      await temp.writeAsString(value, flush: true);
      await _replace(temp, file);
    } catch (_) {
      // The write already failed and is rethrown; a temporary file that cannot be removed goes with the next clear().
      await temp.delete().then<void>((_) {}, onError: (_) {});
      rethrow;
    }
  }

  Future<void> _replace(File source, File target) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await source.rename(target.path);
        return;
      } on FileSystemException catch (error) {
        // Antivirus and indexers briefly lock a freshly written file on Windows (access denied, sharing violation).
        final code = error.osError?.errorCode;
        if (!Platform.isWindows || attempt == 3 || (code != 5 && code != 32)) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 20 * attempt));
      }
    }
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
