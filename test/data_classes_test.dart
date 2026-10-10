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

    test('formats by best-fit metric with truncation', () {
      final cases = <FormattedFilesize, String>{
        FormattedFilesize(): '0B',
        FormattedFilesize(bytes: kb - 1): '1023B',
        FormattedFilesize(kbytes: 1): '1KB',
        FormattedFilesize(bytes: mb - 1): '1023KB',
        FormattedFilesize(bytes: mb + mb * 9 ~/ 10): '1MB',
        FormattedFilesize(mbytes: 2): '2MB',
        FormattedFilesize(gbytes: 3): '3GB',
      };

      for (final MapEntry(key: size, value: expected) in cases.entries) {
        expect(size.toString(), expected, reason: '${size.bytes} bytes');
      }
    });

    test('equals by byte count across units', () {
      expect(FormattedFilesize(kbytes: 1024), FormattedFilesize(mbytes: 1));
      expect(FormattedFilesize(kbytes: 1024).hashCode, FormattedFilesize(mbytes: 1).hashCode);
    });

    test('rejects several size arguments', () {
      expect(() => FormattedFilesize(bytes: 1, kbytes: 1), throwsA(isA<AssertionError>()));
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

    test('explicit-null construction is distinct from unset', () {
      final unset = FinalValue<String?>();
      final explicitNull = FinalValue<String?>.withValue(null);

      expect(unset.isSet, isFalse);
      expect(explicitNull.isSet, isTrue);
      expect(explicitNull.value, isNull);
      expect(unset, isNot(equals(explicitNull)));
      expect(unset.hashCode, isNot(equals(explicitNull.hashCode)));
      expect(() => explicitNull.value = 'later', throwsA(anyOf(isA<StateError>(), isA<AssertionError>())));
    });

    test('take returns an assigned null and throws StateError when unset', () {
      expect(FinalValue<String?>.withValue(null).take, isNull);
      expect(FinalValue<String?>.withValue(null).requiredValue, isNull);
      expect(() => FinalValue<int>().take, throwsStateError);
    });

    test('null positional value leaves the instance unset', () {
      final value = FinalValue<int>(null);

      expect(value.isSet, isFalse);
      value.value = 1;
      expect(value.take, 1);
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

    test('initializes nullable values once even when the result is null', () {
      var calls = 0;
      final lazy = Lazy<String?>(() {
        calls++;
        return null;
      });

      expect(lazy(), isNull);
      expect(lazy(), isNull);
      expect(calls, 1);
    });

    test('retries initialization after the initializer throws', () {
      var calls = 0;
      final lazy = Lazy<int>(() {
        calls++;
        if (calls == 1) {
          throw StateError('first call fails');
        }
        return 42;
      });

      expect(lazy.call, throwsStateError);
      expect(lazy(), 42);
      expect(calls, 2);
    });
  });

  group('Loadable', () {
    test('copyWith preserves nullable fields when omitted', () {
      final stack = StackTrace.fromString('original');
      final source = Loadable<int?>(7, isLoading: true, error: 'failure', stack: stack, defaultBuilder: () => 9);

      final copy = source.copyWith();

      expect(copy.value, 7);
      expect(copy.isLoading, isTrue);
      expect(copy.error, 'failure');
      expect(copy.stack, same(stack));
      expect(copy.defaultBuilder?.call(), 9);
    });

    test('copyWith assigns values including explicit null', () {
      final source = Loadable<int?>(7, isLoading: true, error: 'failure', stack: StackTrace.current, defaultBuilder: () => 9);

      final copy = source.copyWith(value: null, error: null, stack: null, defaultBuilder: null);

      expect(copy.value, isNull);
      expect(copy.error, isNull);
      expect(copy.stack, isNull);
      expect(copy.defaultBuilder, isNull);
    });

    test('copyWith clears fields with the public clear sentinel', () {
      final source = Loadable<int?>(7, isLoading: true, error: 'failure', stack: StackTrace.current, defaultBuilder: () => 9);

      final copy = source.copyWith(
        value: Loadable.clearValue,
        error: Loadable.clearValue,
        stack: Loadable.clearValue,
        defaultBuilder: Loadable.clearValue,
      );

      expect(copy.value, isNull);
      expect(copy.error, isNull);
      expect(copy.stack, isNull);
      expect(copy.defaultBuilder, isNull);
    });

    test('clearError clears the error and its stack together', () {
      final source = Loadable<int?>(7, error: StateError('failure'), stack: StackTrace.current);

      final cleared = source.clearError();

      expect(cleared.error, isNull);
      expect(cleared.stack, isNull);
      expect(cleared.value, 7);
    });

    test('clear removes the error and its stack by default', () {
      final source = Loadable<int?>(7, error: StateError('failure'), stack: StackTrace.current);

      final cleared = source.clear();

      expect(cleared.error, isNull);
      expect(cleared.stack, isNull);
    });

    test('clear preserves the error and its stack when error is false', () {
      final error = StateError('failure');
      final stack = StackTrace.current;
      final source = Loadable<int?>(7, error: error, stack: stack);

      final cleared = source.clear(error: false);

      expect(cleared.error, same(error));
      expect(cleared.stack, same(stack));
    });

    test('clear keeps value and loading when asked', () {
      final cleared = Loadable<int>(7, isLoading: true, error: 'failure').clear(value: false, loading: false);

      expect(cleared.value, 7);
      expect(cleared.isLoading, isTrue);
      expect(cleared.error, isNull);
    });

    test('copyWith keeps the value type', () {
      expect(Loadable<int>(1).copyWith(isLoading: true), isA<Loadable<int>>());
    });

    test('transitions change only their own field', () {
      final stack = StackTrace.fromString('original');
      final source = Loadable<int>(7, isLoading: true, error: 'failure', stack: stack, defaultBuilder: () => 9);

      final idle = source.idle();
      expect((idle.isLoading, idle.value, idle.error, idle.stack), (false, 7, 'failure', stack));

      final loading = idle.loading();
      expect((loading.isLoading, loading.value, loading.error), (true, 7, 'failure'));

      final result = source.result(8);
      expect((result.isLoading, result.value, result.error), (true, 8, 'failure'));

      final failed = source.fail('other');
      expect((failed.isLoading, failed.value, failed.error, failed.stack), (true, 7, 'other', null));

      final cleared = source.clearResult();
      expect((cleared.isLoading, cleared.value, cleared.v, cleared.error), (true, null, 9, 'failure'));

      final changed = source.change<String>('x');
      expect((changed.isLoading, changed.value, changed.error, changed.defaultBuilder), (true, 'x', 'failure', null));
    });

    test('default value is used by accessors but not by hasValue', () {
      final withDefault = Loadable<int>.idle(defaultBuilder: () => 3);

      expect(withDefault.hasValue, isFalse);
      expect(withDefault.v, 3);
      expect(withDefault.rv, 3);
      expect(withDefault.valueOr(5), 3);
      expect(withDefault.or(5), 3);
      expect(const Loadable<int>.idle().valueOr(5), 5);
    });

    test('generateKey reflects only the included state parts', () {
      expect(Loadable<int>(1).generateKey(), isNot(Loadable<int>(2).generateKey()));
      expect(Loadable<int>(1).generateKey(), isNot(Loadable<int>(1, isLoading: true).generateKey()));
      expect(Loadable<int>(1).generateKey(includeValue: false), Loadable<int>(2).generateKey(includeValue: false));
      expect(Loadable<int>(1).generateKey(includeLoading: false), Loadable<int>(1, isLoading: true).generateKey(includeLoading: false));
    });
  });

  group('Maybe', () {
    test('treats null and nothing as the same empty value', () {
      expect(const Maybe<int>(null), const Maybe<int>.nothing());
      expect(const Maybe<int>.nothing().hasValue, isFalse);
      expect(const Maybe<int>.nothing().or(2), 2);
      expect(1.asMaybe.or(2), 1);
    });
  });

  group('Pair and Range', () {
    test('equality and hash depend on both values and their order', () {
      expect(const Pair(1, 2), const Pair.from(first: 1, second: 2));
      expect(const Pair(1, 2).hashCode, const Pair.from(first: 1, second: 2).hashCode);
      expect(const Pair(1, 2).hashCode, isNot(const Pair(2, 1).hashCode));
      expect(const Range(1, 2), const Range.from(from: 1, till: 2));
      expect(const Range(1, 2).hashCode, isNot(const Range(2, 1).hashCode));
    });

    test('range reports which bounds are set', () {
      final cases = <Range<int>, (bool, bool)>{
        const Range(): (false, false),
        const Range(1): (true, false),
        const Range.from(till: 2): (true, false),
        const Range(1, 2): (true, true),
      };

      for (final MapEntry(key: range, value: expected) in cases.entries) {
        expect((range.hasAnyRange, range.hasBothRanges), expected, reason: '$range');
      }
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

    test('consume handles zero and oversized counts', () {
      final source = StringSource('abc');

      expect(source.consume(count: 0), '');
      expect(source.position, 0);
      expect(source.consume(count: 10), 'abc');
      expect(source.consume(), '');
    });

    test('peek, remaining and rewind follow the direction', () {
      for (final (backwards, firstPeek, restAfterOne) in [(false, 'a', 'bc'), (true, 'c', 'ab')]) {
        final source = StringSource('abc', backwards: backwards);

        expect(source.peek, firstPeek, reason: 'backwards: $backwards');
        source.consume();
        expect(source.remaining, restAfterOne, reason: 'backwards: $backwards');
        source.rewind();
        expect(source.remaining, 'abc', reason: 'backwards: $backwards');
        source.consume(count: 3);
        expect((source.hasMore, source.peek), (false, ''), reason: 'backwards: $backwards');
      }
    });

    test('consumeUntil returns the match and moves past it', () {
      final source = StringSource('ab-cd');

      expect(source.consumeUntil((it) => it == '-'), '-');
      expect(source.remaining, 'cd');
      expect(source.consumeUntil((it) => it == '-'), isNull);
      expect(source.hasMore, isFalse);
    });

    test('toString marks the cursor in every position and direction', () {
      String render(String text, {bool backwards = false, int consumed = 0}) {
        final source = StringSource(text, backwards: backwards)..consume(count: consumed);
        return source.toString();
      }

      expect(render('abc'), 'StringSource{text: >abc}');
      expect(render('abc', consumed: 1), 'StringSource{text: a>bc}');
      expect(render('abc', consumed: 3), 'StringSource{text: abc<}');
      expect(render('abc', backwards: true), 'StringSource{text: abc<}');
      expect(render('abc', backwards: true, consumed: 1), 'StringSource{text: ab<c}');
      expect(render('abc', backwards: true, consumed: 3), 'StringSource{text: <abc}');
      expect(render(''), 'StringSource{text: <}');
      expect(render('', backwards: true), 'StringSource{text: <}');
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

    test('setValue notifies only on value or visibility change', () {
      final value = VisibleValue<String>('x', false);
      var changes = 0;

      value.setValue('y', onChanged: () => changes++);
      expect((value.value, value.isVisible, changes), ('y', true, 1));

      value.setValue('y', onChanged: () => changes++);
      expect(changes, 1);

      value.setValue(null, isVisible: true, onChanged: () => changes++);
      expect((value.value, value.isVisible, changes), ('y', true, 1));
    });

    test('assign stores null for a nullable type', () {
      final value = VisibleValue<String?>('x');
      var changes = 0;

      value.assign(null, onChanged: () => changes++);

      expect((value.value, value.isVisible, changes), (null, true, 1));
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
