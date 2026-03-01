import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormattedFilesize', () {
    test('converts bytes and picks metric', () {
      const bytes = 3 * mb;
      final size = FormattedFilesize(bytes: bytes);

      expect(size.inMB, 3);
      expect(size.metric, FilesizeMetric.mbytes);
      expect(size.toString(), '3MB');
    });
  });

  group('FinalValue', () {
    test('stores value once', () {
      final value = FinalValue<int>();
      value.value = 10;

      expect(value.isSet, isTrue);
      expect(value.take, 10);
      expect(() => value.value = 20, throwsA(anyOf(isA<StateError>(), isA<AssertionError>())));
    });

    test('null assignment is treated as set', () {
      final value = FinalValue<String?>();
      value.value = null;

      expect(value.isSet, isTrue);
      expect(value.tryTake, isNull);
      expect(() => value.value = 'later', throwsA(anyOf(isA<StateError>(), isA<AssertionError>())));
    });
  });

  group('Lazy', () {
    test('initializes once and caches result', () {
      var calls = 0;
      final lazy = Lazy<int>(() {
        calls++;
        return 42;
      });

      expect(lazy(), 42);
      expect(lazy(), 42);
      expect(calls, 1);
    });
  });

  group('StringSource', () {
    test('consume works forward for count > 1', () {
      final source = StringSource('abcd');
      expect(source.consume(count: 2), 'ab');
      expect(source.position, 2);
      expect(source.consume(count: 2), 'cd');
      expect(source.hasMore, isFalse);
    });

    test('consume works backward for count > 1', () {
      final source = StringSource('abcd', backwards: true);
      expect(source.consume(count: 2), 'dc');
      expect(source.position, 1);
      expect(source.consume(count: 2), 'ba');
      expect(source.hasMore, isFalse);
    });

    test('consume throws for negative count', () {
      final source = StringSource('abc');
      expect(() => source.consume(count: -1), throwsA(isA<IllegalArgumentException>()));
    });
  });

  group('VisibleValue', () {
    test('setValue(null) triggers change only when visibility changes', () {
      final value = VisibleValue<String>('x', true);
      var changes = 0;

      value.setValue(null, onChanged: () => changes++);
      expect(value.isVisible, isFalse);
      expect(changes, 1);

      value.setValue(null, onChanged: () => changes++);
      expect(value.isVisible, isFalse);
      expect(changes, 1);
    });
  });

  group('Cancellable', () {
    test('StreamCancellable stops after mapper returns false', () async {
      final controller = StreamController<int>();
      final seen = <int>[];

      StreamCancellable<int>(
        controller.stream,
        (event) {
          seen.add(event);
          return event < 2;
        },
      );

      controller.add(1);
      controller.add(2);
      controller.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await controller.close();

      expect(seen, [1, 2]);
    });

    test('ListenableCancellable invokes mapper immediately and can cancel itself', () async {
      final notifier = ValueNotifier<int>(0);
      final seen = <int>[];

      ListenableCancellable<int>(
        notifier,
        (value) {
          seen.add(value);
          return value == 0;
        },
      );

      await Future<void>.delayed(Duration.zero);
      notifier.value = 1;
      await Future<void>.delayed(Duration.zero);
      notifier.value = 2;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(seen, [0, 1]);
      notifier.dispose();
    });

    test('NotifierCancellable invokes mapper immediately and can cancel itself', () async {
      final notifier = ChangeNotifier();
      var calls = 0;

      NotifierCancellable(
        notifier,
        () {
          calls++;
          return calls < 2;
        },
      );

      await Future<void>.delayed(Duration.zero);
      notifier.notifyListeners();
      await Future<void>.delayed(Duration.zero);
      notifier.notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(calls, 2);
      notifier.dispose();
    });
  });
}
