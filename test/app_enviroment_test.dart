import 'dart:async';
import 'dart:convert';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnviroment', () {
    late Map<Enviroment, String> previousEnviroments;

    setUp(() {
      previousEnviroments = Enviroments.enviroments;
      Enviroments.enviroments = {
        Enviroment.prod: 'https://production.example',
      };
    });

    tearDown(() {
      Enviroments.enviroments = previousEnviroments;
    });

    test('parses a valid serialized environment', () {
      final environment = AppEnviroment.from(
        jsonEncode({
          'enviroment': Enviroment.stage.name,
          'host': 'https://stage.example',
        }),
      );

      expect(environment.enviroment, Enviroment.stage.name);
      expect(environment.host, 'https://stage.example');
      expect(environment.isProd, isFalse);
      expect(
        environment.toString(),
        'AppEnviroment{enviroment: stage, host: https://stage.example}',
      );
    });

    test('falls back to the configured production environment for invalid data', () {
      final environment = AppEnviroment.from('{not json');

      expect(environment.enviroment, Enviroment.prod.name);
      expect(environment.host, 'https://production.example');
      expect(environment.isProd, isTrue);
    });

    test('save writes serialized values and load reconstructs them', () async {
      final property = _MemoryStringProperty('unused');
      const expected = AppEnviroment(
        enviroment: 'custom',
        host: 'http://localhost:8080',
      );

      await expected.save(property);

      expect(property.setCount, 1);
      expect(
        jsonDecode(property.cachedValue),
        {
          'enviroment': expected.enviroment,
          'host': expected.host,
        },
      );

      final loaded = await AppEnviroment.load(property);

      expect(property.getCount, 1);
      expect(loaded.enviroment, expected.enviroment);
      expect(loaded.host, expected.host);
    });
  });
}

class _MemoryStringProperty implements StorableProperty<String> {
  String _value;
  int getCount = 0;
  int setCount = 0;

  _MemoryStringProperty(this._value);

  @override
  String get cachedValue => _value;

  @override
  Future<void> delete() async {
    _value = '';
  }

  @override
  FutureOr<bool> exists() => true;

  @override
  FutureOr<String> getValue() {
    getCount += 1;
    return _value;
  }

  @override
  Future<void> setValue(String val) async {
    setCount += 1;
    _value = val;
  }
}
