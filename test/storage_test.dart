import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

enum _StorageMode { first, second }

void main() {
  final storageFactories = [
    _StorageFactory('memory', () async => _StorageFixture(MemoryStorage(), () async {})),
    _StorageFactory('file', () async {
      final root = await Directory.systemTemp.createTemp('flutter_commons_storage_test_');
      return _StorageFixture(
        FileStorage(parentDirectory: Directory('${root.path}${Platform.pathSeparator}properties')),
        () => root.delete(recursive: true),
      );
    }),
  ];

  final propertyCases = <_PropertyCase>[
    _PropertyCase('bool', false, true, 'not-a-bool', (storage, onSave) => BoolProperty(storage, 'value', onSave: onSave)),
    _PropertyCase('int', 0, 4, 'not-an-int', (storage, onSave) => IntProperty(storage, 'value', onSave: onSave)),
    _PropertyCase('double', 0.0, 2.5, 'not-a-double', (storage, onSave) => DoubleProperty(storage, 'value', onSave: onSave)),
    _PropertyCase('string', '', 'saved', null, (storage, onSave) => StringProperty(storage, 'value', onSave: onSave)),
    _PropertyCase(
      'json',
      const {'state': 'default'},
      const {'state': 'saved'},
      '{malformed',
      (storage, onSave) => JsonProperty<Map<String, dynamic>>(
        storage,
        'value',
        fromJson: (json) => json,
        toJson: (value) => value,
        ifNotExist: () => {'state': 'default'},
        onSave: onSave,
      ),
    ),
    _PropertyCase(
      'date time',
      DateTime(0),
      DateTime.utc(2026, 9, 6, 12),
      'not-a-date',
      (storage, onSave) => DateTimeProperty(storage, 'value', onSave: onSave),
      (actual, expected) => (actual as DateTime).isAtSameMomentAs(expected as DateTime),
    ),
    _PropertyCase(
      'enum',
      _StorageMode.first,
      _StorageMode.second,
      'unknown',
      (storage, onSave) => EnumProperty(storage, 'value', values: _StorageMode.values, defaultValue: _StorageMode.first, onSave: onSave),
    ),
  ];

  for (final storageFactory in storageFactories) {
    group('${storageFactory.name} storage contract', () {
      test('raw get, set, delete and clear are deterministic', () async {
        final fixture = await storageFactory.create();
        addTearDown(fixture.dispose);
        final storage = fixture.storage;

        expect(await storage.get(''), '');
        expect(await storage.exists(''), isFalse);
        if (storageFactory.name == 'file') {
          await expectLater(storage.get('missing'), throwsA(isA<FileSystemException>()));
        } else {
          expect(await storage.get('missing'), '');
        }
        expect(await storage.exists('missing'), isFalse);
        await storage.set('one', '1');
        expect(await storage.get('one'), '1');
        await storage.delete('one');
        expect(await storage.exists('one'), isFalse);
        if (storageFactory.name == 'file') {
          await expectLater(storage.get('one'), throwsA(isA<FileSystemException>()));
        } else {
          expect(await storage.get('one'), '');
        }
        await storage.set('one', '1');
        await storage.clear();
        expect(await storage.exists('one'), isFalse);
      });

      for (final propertyCase in propertyCases) {
        test('${propertyCase.name} property keeps cache, persistence and callbacks consistent', () async {
          final fixture = await storageFactory.create();
          addTearDown(fixture.dispose);
          final callbacks = <Object?>[];
          final property = propertyCase.create(fixture.storage, callbacks.add);

          _expectPropertyValue(property.cachedValue, propertyCase.defaultValue, propertyCase);
          _expectPropertyValue(await property.getValue(), propertyCase.defaultValue, propertyCase);
          expect(await property.exists(), isFalse);

          await property.setValue(propertyCase.savedValue);
          _expectPropertyValue(property.cachedValue, propertyCase.savedValue, propertyCase);
          _expectPropertyValue(await property.getValue(), propertyCase.savedValue, propertyCase);
          expect(callbacks, [propertyCase.savedValue]);

          await property.delete();
          expect(await property.exists(), isFalse);
          _expectPropertyValue(property.cachedValue, propertyCase.defaultValue, propertyCase);
          _expectPropertyValue(await property.getValue(), propertyCase.defaultValue, propertyCase);
          expect(callbacks, [propertyCase.savedValue]);
        });

        if (propertyCase.malformedValue case final malformedValue?) {
          test('${propertyCase.name} property recovers malformed data to its default with a safe diagnostic', () async {
            final fixture = await storageFactory.create();
            addTearDown(fixture.dispose);
            final callbacks = <Object?>[];
            final property = propertyCase.create(fixture.storage, callbacks.add);
            await property.setValue(propertyCase.savedValue);
            callbacks.clear();
            await fixture.storage.set('value', malformedValue);
            final messages = <String?>[];
            final previousDebugPrint = debugPrint;
            debugPrint = (message, {wrapWidth}) => messages.add(message);
            addTearDown(() => debugPrint = previousDebugPrint);

            _expectPropertyValue(await property.getValue(), propertyCase.defaultValue, propertyCase);
            if (propertyCase.name == 'json') {
              expect(await fixture.storage.get('value'), '{"state":"default"}');
            } else {
              expect(await fixture.storage.get('value'), malformedValue);
            }
            _expectPropertyValue(property.cachedValue, propertyCase.defaultValue, propertyCase);
            expect(callbacks, isEmpty);
            expect(messages, hasLength(1));
            expect(messages.single, contains('default'));
            expect(messages.single, isNot(contains(malformedValue)));
          });
        }
      }

      test('onSave observes the updated cache', () async {
        final fixture = await storageFactory.create();
        addTearDown(fixture.dispose);
        late StringProperty property;
        final observedCache = <String>[];
        property = StringProperty(fixture.storage, 'value', onSave: (_) => observedCache.add(property.cachedValue));

        await property.setValue('saved');

        expect(observedCache, ['saved']);
      });

      test('revertable stages deletion until commit and can cancel it', () async {
        final fixture = await storageFactory.create();
        addTearDown(fixture.dispose);
        await fixture.storage.set('value', 'persisted');
        final revertable = RevertableProperty(StringProperty(fixture.storage, 'value', defaultValue: 'default'));

        expect(await revertable.getValue(), 'persisted');
        expect(revertable.hasChanged, isFalse);
        await revertable.setValue('draft');
        expect(revertable.hasChanged, isTrue);
        await revertable.revert();
        expect(revertable.cachedValue, 'persisted');
        await revertable.setValue('committed');
        await revertable.commit();
        expect(await fixture.storage.get('value'), 'committed');
        expect(revertable.hasChanged, isFalse);

        await revertable.delete();
        expect(await fixture.storage.get('value'), 'committed');
        expect(await revertable.exists(), isTrue);
        expect(revertable.cachedValue, 'committed');
        expect(revertable.hasChanged, isTrue);
        await revertable.revert();
        expect(revertable.cachedValue, 'committed');
        expect(revertable.hasChanged, isFalse);

        await revertable.delete();
        await revertable.commit();
        expect(await fixture.storage.exists('value'), isFalse);
        expect(revertable.cachedValue, 'default');
        expect(revertable.hasChanged, isFalse);
      });

      test('setting a new draft replaces pending deletion', () async {
        final fixture = await storageFactory.create();
        addTearDown(fixture.dispose);
        final child = StringProperty(fixture.storage, 'value');
        await child.setValue('original');
        final property = RevertableProperty(child);

        await property.delete();
        await property.setValue('replacement');
        await property.commit();

        expect(await fixture.storage.get('value'), 'replacement');
        expect(property.cachedValue, 'replacement');
        expect(property.hasChanged, isFalse);
      });

      test('listenable notifies after each cache refresh', () async {
        final fixture = await storageFactory.create();
        addTearDown(fixture.dispose);
        final property = ListenableProperty(StringProperty(fixture.storage, 'value', defaultValue: 'default'));
        final observedCache = <String>[];
        property.addListener(() => observedCache.add(property.cachedValue));

        await property.getValue();
        await property.setValue('saved');
        await property.delete();

        expect(observedCache, ['default', 'saved', 'default']);
      });
    });
  }

  test('file storage rejects property paths outside its parent directory', () async {
    final root = await Directory.systemTemp.createTemp('flutter_commons_storage_path_test_');
    addTearDown(() => root.delete(recursive: true));
    final storage = FileStorage(parentDirectory: Directory('${root.path}${Platform.pathSeparator}properties'));

    await expectLater(storage.set('../outside', 'value'), throwsArgumentError);
    await expectLater(storage.set('..\\outside', 'value'), throwsArgumentError);
    await expectLater(storage.set('/absolute', 'value'), throwsArgumentError);
    await expectLater(storage.set('C:/absolute', 'value'), throwsArgumentError);
    await storage.set('nested/value', 'value');
    expect(await storage.get('nested/value'), 'value');
    expect(await File('${root.path}${Platform.pathSeparator}outside').exists(), isFalse);
  });

  test('file storage treats empty names as an absent value', () async {
    final root = await Directory.systemTemp.createTemp('flutter_commons_storage_empty_name_test_');
    addTearDown(() => root.delete(recursive: true));
    final storage = FileStorage(parentDirectory: Directory('${root.path}${Platform.pathSeparator}properties'));

    expect(await storage.get(''), '');
    expect(await storage.exists(''), isFalse);
    await expectLater(storage.set('', 'value'), throwsArgumentError);
    await expectLater(storage.delete(''), throwsArgumentError);
  });

  test('legacy StorablePropertyImpl subclasses compile and retain custom overrides', () async {
    final storage = MemoryStorage();
    final property = _LegacyStringProperty(storage);

    expect(await property.getValue(), 'legacy default');
    await property.setValue('saved');
    expect(property.cachedValue, 'saved');
    expect(await storage.get('legacy'), 'saved');
    await property.delete();
    expect(property.cachedValue, 'legacy default');
  });

  test('nullable revertable distinguishes a stored null from pending deletion', () async {
    final storage = MemoryStorage();
    final child = JsonProperty<String?>(
      storage,
      'value',
      fromJson: (json) => json['value'] as String?,
      toJson: (value) => {'value': value},
      ifNotExist: () => 'default',
    );
    final property = RevertableProperty(child);

    await property.setValue(null);
    expect(property.cachedValue, isNull);
    await property.commit();
    expect(await storage.get('value'), '{"value":null}');
    expect(property.hasChanged, isFalse);
    await property.delete();
    expect(property.hasChanged, isTrue);
    await property.revert();
    expect(property.cachedValue, isNull);
    expect(property.hasChanged, isFalse);
    await property.commit();
    expect(await storage.exists('value'), isTrue);
  });

  for (final rawValue in ['[]', '{"value":3}']) {
    test('JSON schema corruption recovers and rewrites the default ($rawValue)', () async {
      final storage = MemoryStorage();
      final property = JsonProperty<String>(
        storage,
        'value',
        fromJson: (json) => json['value'] as String,
        toJson: (value) => {'value': value},
        ifNotExist: () => 'default',
      );
      await storage.set('value', rawValue);

      expect(await property.getValue(), 'default');
      expect(property.cachedValue, 'default');
      expect(await storage.get('value'), '{"value":"default"}');
    });
  }

  test('corrupt primitives use the configured default rather than the previous cached value', () async {
    final storage = MemoryStorage();
    final property = IntProperty(storage, 'value', defaultValue: 42);
    await property.setValue(7);
    await storage.set('value', 'invalid');

    expect(await property.getValue(), 42);
    expect(property.cachedValue, 42);
  });

  test('storage read errors are not silently treated as corrupt data', () async {
    final storage = _FailingStorage();
    final property = IntProperty(storage, 'value', defaultValue: 42);
    await property.setValue(7);
    storage.failReads = true;

    await expectLater(property.getValue(), throwsA(same(storage.failure)));
    expect(property.cachedValue, 7);
  });

  test('failed deletion commit keeps its draft retryable and revertible', () async {
    final storage = _FailingStorage();
    final child = StringProperty(storage, 'value');
    await child.setValue('original');
    final property = RevertableProperty(child);
    await property.delete();
    storage.failDeletes = true;

    await expectLater(property.commit(), throwsA(same(storage.failure)));
    expect(await storage.get('value'), 'original');
    expect(property.hasChanged, isTrue);
    await property.revert();
    expect(property.cachedValue, 'original');
    expect(property.hasChanged, isFalse);

    await property.delete();
    storage.failDeletes = false;
    await property.commit();
    expect(await storage.exists('value'), isFalse);
    expect(property.hasChanged, isFalse);
  });

  test('revertable keeps edits made while a commit is pending as an unsaved draft', () async {
    final child = _GatedStringProperty('original');
    final property = RevertableProperty(child);
    await property.setValue('committed');

    final commit = property.commit();
    await child.writeStarted;
    await property.setValue('unsaved');
    child.completeWrite();
    await commit;

    expect(child.persistedValue, 'committed');
    expect(property.cachedValue, 'unsaved');
    expect(property.hasChanged, isTrue);
  });

  test('deletion commit reloads a custom child whose delete leaves its cache unchanged', () async {
    final child = _GatedDeletionProperty();
    final property = RevertableProperty(child);
    await property.delete();

    final commit = property.commit();
    await child.deleteStarted;
    child.completeDelete();
    await commit;

    expect(child.persistedValue, isNull);
    expect(property.cachedValue, 'default');
    expect(property.hasChanged, isFalse);
    await property.setValue('draft');
    await property.revert();
    expect(property.cachedValue, 'default');
  });

  for (final duringReload in [false, true]) {
    final phase = duringReload ? 'reload' : 'delete';

    test('deletion commit preserves a new draft during $phase', () async {
      final child = _GatedDeletionProperty(delayRead: duringReload);
      final property = RevertableProperty(child);
      await property.delete();

      final commit = property.commit();
      await child.deleteStarted;
      if (duringReload) {
        child.completeDelete();
        await child.readStarted;
      }
      await property.setValue('unsaved');
      if (duringReload) {
        child.completeRead();
      } else {
        child.completeDelete();
      }
      await commit;

      expect(child.persistedValue, isNull);
      expect(property.cachedValue, 'unsaved');
      expect(property.hasChanged, isTrue);
      await property.revert();
      expect(property.cachedValue, 'default');
      expect(property.hasChanged, isFalse);
    });

    test('deletion commit preserves a reverted value during $phase', () async {
      final child = _GatedDeletionProperty(delayRead: duringReload);
      final property = RevertableProperty(child);
      await property.delete();

      final commit = property.commit();
      await child.deleteStarted;
      if (duringReload) {
        child.completeDelete();
        await child.readStarted;
      }
      await property.revert();
      expect(property.cachedValue, 'original');
      expect(property.hasChanged, isFalse);
      if (duringReload) {
        child.completeRead();
      } else {
        child.completeDelete();
      }
      await commit;

      expect(child.persistedValue, isNull);
      expect(property.cachedValue, 'original');
      expect(property.hasChanged, isTrue);
      await property.commit();
      expect(child.persistedValue, 'original');
      expect(property.hasChanged, isFalse);
    });
  }

  test('deletion commit preserves a newly staged deletion', () async {
    final child = _GatedDeletionProperty();
    final property = RevertableProperty(child);
    await property.delete();

    final commit = property.commit();
    await child.deleteStarted;
    await property.setValue('draft');
    await property.delete();
    child.completeDelete();
    await commit;

    expect(property.cachedValue, 'default');
    expect(property.hasChanged, isTrue);
    await property.revert();
    expect(property.cachedValue, 'default');
    expect(property.hasChanged, isFalse);
  });

  for (final failRead in [false, true]) {
    final phase = failRead ? 'reload' : 'delete';

    test('failed deletion $phase preserves a concurrent draft and the previous committed value', () async {
      final child = _GatedDeletionProperty()
        ..failDeletes = !failRead
        ..failReads = failRead;
      final property = RevertableProperty(child);
      await property.delete();

      final commit = property.commit();
      final failure = expectLater(commit, throwsA(same(child.failure)));
      await child.deleteStarted;
      await property.setValue('unsaved');
      child.completeDelete();
      await failure;

      expect(child.persistedValue, failRead ? isNull : 'original');
      expect(property.cachedValue, 'unsaved');
      expect(property.hasChanged, isTrue);
      await property.revert();
      expect(property.cachedValue, 'original');
      expect(property.hasChanged, isFalse);
    });
  }

  test('failed deletion reload leaves the staged deletion retryable', () async {
    final child = _GatedDeletionProperty()..failReads = true;
    final property = RevertableProperty(child);
    await property.delete();

    final commit = property.commit();
    final failure = expectLater(commit, throwsA(same(child.failure)));
    await child.deleteStarted;
    child.completeDelete();
    await failure;

    expect(child.persistedValue, isNull);
    expect(property.cachedValue, 'original');
    expect(property.hasChanged, isTrue);
    child.failReads = false;
    await property.commit();
    expect(property.cachedValue, 'default');
    expect(property.hasChanged, isFalse);
  });

  test('revertable keeps deletion staged while a value commit is pending', () async {
    final child = _GatedStringProperty('original');
    final property = RevertableProperty(child);
    await property.setValue('committed');

    final commit = property.commit();
    await child.writeStarted;
    await property.delete();
    child.completeWrite();
    await commit;

    expect(child.persistedValue, 'committed');
    expect(property.cachedValue, 'committed');
    expect(property.hasChanged, isTrue);
    await property.revert();
    expect(property.cachedValue, 'committed');
    expect(property.hasChanged, isFalse);
  });
}

class _FailingStorage extends MemoryStorage {
  final failure = StateError('Storage operation failed');
  bool failReads = false;
  bool failDeletes = false;

  @override
  FutureOr<String> get(String name) {
    if (failReads) throw failure;
    return super.get(name);
  }

  @override
  Future<void> delete(String name) async {
    if (failDeletes) throw failure;
    await super.delete(name);
  }
}

class _GatedStringProperty implements StorableProperty<String> {
  final Completer<void> _writeStarted = Completer<void>();
  final Completer<void> _writeCompleted = Completer<void>();

  String _cachedValue;
  String? persistedValue;

  _GatedStringProperty(this._cachedValue) : persistedValue = _cachedValue;

  Future<void> get writeStarted => _writeStarted.future;

  @override
  String get cachedValue => _cachedValue;

  void completeWrite() => _writeCompleted.complete();

  @override
  Future<void> delete() async {
    persistedValue = null;
  }

  @override
  Future<String> getValue() async => _cachedValue;

  @override
  Future<bool> exists() async => persistedValue != null;

  @override
  Future<void> setValue(String value) async {
    _writeStarted.complete();
    await _writeCompleted.future;
    _cachedValue = value;
    persistedValue = value;
  }
}

class _GatedDeletionProperty implements StorableProperty<String> {
  final Completer<void> _deleteStarted = Completer<void>();
  final Completer<void> _deleteCompleted = Completer<void>();
  final Completer<void> _readStarted = Completer<void>();
  final Completer<void>? _readCompleted;
  final failure = StateError('Property operation failed');

  String _cachedValue = 'original';
  String? persistedValue = 'original';
  bool failDeletes = false;
  bool failReads = false;

  _GatedDeletionProperty({bool delayRead = false}) : _readCompleted = delayRead ? Completer<void>() : null;

  Future<void> get deleteStarted => _deleteStarted.future;
  Future<void> get readStarted => _readStarted.future;

  void completeDelete() => _deleteCompleted.complete();
  void completeRead() => _readCompleted!.complete();

  @override
  String get cachedValue => _cachedValue;

  @override
  Future<void> delete() async {
    if (!_deleteStarted.isCompleted) _deleteStarted.complete();
    await _deleteCompleted.future;
    if (failDeletes) throw failure;
    persistedValue = null;
  }

  @override
  Future<String> getValue() async {
    if (!_readStarted.isCompleted) _readStarted.complete();
    final readCompleted = _readCompleted;
    if (readCompleted != null) await readCompleted.future;
    if (failReads) throw failure;
    return _cachedValue = persistedValue ?? 'default';
  }

  @override
  Future<void> setValue(String value) async {
    persistedValue = value;
    _cachedValue = value;
  }

  @override
  Future<bool> exists() async => persistedValue != null;
}

class _StorageFactory {
  final String name;
  final Future<_StorageFixture> Function() create;

  const _StorageFactory(this.name, this.create);
}

class _StorageFixture {
  final PropertyStorage storage;
  final FutureOr<void> Function() dispose;

  const _StorageFixture(this.storage, this.dispose);
}

class _PropertyCase {
  final String name;
  final Object? defaultValue;
  final Object? savedValue;
  final String? malformedValue;
  final StorableProperty<Object?> Function(PropertyStorage storage, void Function(Object?) onSave) create;
  final bool Function(Object? actual, Object? expected)? isEqual;

  const _PropertyCase(this.name, this.defaultValue, this.savedValue, this.malformedValue, this.create, [this.isEqual]);
}

void _expectPropertyValue(Object? actual, Object? expected, _PropertyCase propertyCase) {
  final isEqual = propertyCase.isEqual;
  if (isEqual == null) {
    expect(actual, expected);
  } else {
    expect(isEqual(actual, expected), isTrue);
  }
}

class _LegacyStringProperty extends StorablePropertyImpl<String> {
  String _value = 'legacy default';

  _LegacyStringProperty(PropertyStorage storage) : super(storage, 'legacy');

  @override
  String get cachedValue => _value;

  @override
  Future<String> getValue() async {
    if (await storage.exists(name)) {
      _value = await storage.get(name);
    } else {
      _value = 'legacy default';
    }
    return _value;
  }

  @override
  Future<void> setValue(String value) async {
    await super.setValue(value);
    _value = value;
  }
}
