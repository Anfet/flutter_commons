import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IterableExt', () {
    test('distinct keeps unique values when test is omitted', () {
      expect([1, 1, 2, 2, 3].distinct().toList(), [1, 2, 3]);
    });

    test('distinct uses projection key when test is provided', () {
      final values = ['aa', 'ab', 'bc', 'bd'];
      final result = values.distinct((it) => it[0]).toList();
      expect(result, ['aa', 'bc']);
    });

    test('firstNotNullOr returns first non-null mapped value', () {
      final values = [1, 2, 3, 4];
      final result = values.firstNotNullOr<String>((it) => it.isEven ? 'E$it' : null);
      expect(result, 'E2');
    });

    test('maxOf and minOf work with mapper for non-num types', () {
      final values = ['aaa', 'b', 'cc'];
      expect(values.maxOf((it) => it.length), 3);
      expect(values.minOf((it) => it.length), 1);
    });
  });

  group('StringExt', () {
    test('stripNewLines removes actual newline characters', () {
      const source = 'a\nb\r\nc';
      expect(source.stripNewLines, 'abc');
    });
  });

  group('BoolExt', () {
    test('compareTo and compareOrNull follow same ordering', () {
      expect(true.compareTo(false), 1);
      expect(false.compareTo(true), -1);
      expect(true.compareOrNull(false), 1);
      expect(false.compareOrNull(true), -1);
      expect(true.compareOrNull(true), isNull);
    });
  });

  group('CompleterExt', () {
    test('fromFuture completes current completer and returns itself', () async {
      final completer = Completer<int>();
      final returned = completer.fromFuture(Future.value(7));

      expect(identical(returned, completer), isTrue);
      expect(await completer.future, 7);
    });
  });

  group('ListExt', () {
    test('navigation methods throw ListIsEmptyException for empty list', () {
      final values = <int>[];

      expect(() => values.nextOrLast(1), throwsA(isA<ListIsEmptyException>()));
      expect(() => values.nextOrFirst(1), throwsA(isA<ListIsEmptyException>()));
      expect(() => values.priorOrFirst(1), throwsA(isA<ListIsEmptyException>()));
      expect(() => values.priorOrLast(1), throwsA(isA<ListIsEmptyException>()));
    });

    test('navigation methods throw IllegalArgumentException when item is missing', () {
      final values = [1, 2, 3];

      expect(() => values.nextOrLast(4), throwsA(isA<IllegalArgumentException>()));
      expect(() => values.nextOrFirst(4), throwsA(isA<IllegalArgumentException>()));
      expect(() => values.priorOrFirst(4), throwsA(isA<IllegalArgumentException>()));
      expect(() => values.priorOrLast(4), throwsA(isA<IllegalArgumentException>()));
    });

    test('navigation methods keep previous behavior for boundary items', () {
      final values = [1, 2, 3];

      expect(values.nextOrLast(1), 2);
      expect(values.nextOrLast(3), 3);
      expect(values.nextOrFirst(3), 1);
      expect(values.priorOrFirst(1), 1);
      expect(values.priorOrLast(1), 3);
    });
  });

  group('ValueListenableMapExt', () {
    test('maps source values and notifies listeners', () {
      final source = ValueNotifier<int>(2);
      final mapped = source.mapValue<String>((it) => 'v$it');
      addTearDown(() {
        mapped.dispose();
        source.dispose();
      });

      var notifications = 0;
      mapped.addListener(() => notifications++);

      expect(mapped.value, 'v2');
      source.value = 3;
      expect(mapped.value, 'v3');
      expect(notifications, 1);
    });
  });
}
