import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapValue chain', () {
    test('detaches from the source once the tail loses its last listener, without dispose', () {
      final source = _TrackingValueNotifier<int>(1);
      addTearDown(source.dispose);
      final tail = source.mapValue((it) => it * 10).mapValue((it) => 'v$it');
      final seen = <String>[];
      void listener() => seen.add(tail.value);

      expect(source.hasActiveListeners, isFalse);
      tail.addListener(listener);
      expect(source.hasActiveListeners, isTrue);
      source.value = 2;
      tail.removeListener(listener);

      expect(seen, ['v20']);
      expect(source.hasActiveListeners, isFalse);
      source.value = 3;
      expect(tail.value, 'v30');
    });

    test('detaches when the last listener removes itself during notification', () {
      final source = _TrackingValueNotifier<int>(1);
      addTearDown(source.dispose);
      final mapped = source.mapValue((it) => it + 1);
      late VoidCallback once;
      once = () => mapped.removeListener(once);
      mapped.addListener(once);

      source.value = 2;

      expect(source.hasActiveListeners, isFalse);
    });

    test('notifies only when the mapped value changes', () {
      final source = ValueNotifier<int>(1);
      addTearDown(source.dispose);
      final parity = source.mapValue((it) => it.isEven);
      var notifications = 0;
      parity.addListener(() => notifications++);

      source.value = 3;
      source.value = 4;

      expect(notifications, 1);
    });

    testWidgets('ValueListenableBuilder releases the whole chain on unmount', (tester) async {
      final source = _TrackingValueNotifier<int>(1);
      addTearDown(source.dispose);
      final label = source.mapValue((it) => it * 2).mapValue((it) => 'v$it');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<String>(valueListenable: label, builder: (_, value, _) => Text(value)),
        ),
      );
      source.value = 5;
      await tester.pump();
      expect(find.text('v10'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(source.hasActiveListeners, isFalse);
    });
  });

  group('mapValueAsync', () {
    test('applies only the result for the latest source value', () async {
      final source = ValueNotifier<int>(1);
      addTearDown(source.dispose);
      final calls = <int, Completer<String>>{};
      final mapped = source.mapValueAsync((it) => (calls[it] = Completer<String>()).future);
      mapped.addListener(() {});

      source.value = 2;
      calls[2]!.complete('two');
      await _settle();
      calls[1]!.complete('one');
      await _settle();

      expect(mapped.value.value, 'two');
      expect(mapped.value.isLoading, isFalse);
    });

    test('keeps the previous value and stores the error when a call fails', () async {
      final source = ValueNotifier<int>(1);
      addTearDown(source.dispose);
      final failure = StateError('load failed');
      final mapped = source.mapValueAsync((it) async => it == 1 ? 'one' : throw failure);
      mapped.addListener(() {});
      await _settle();

      source.value = 2;
      await _settle();

      expect(mapped.value.value, 'one');
      expect(mapped.value.error, same(failure));
      expect(mapped.value.isLoading, isFalse);
    });

    test('detaching drops the pending call; attaching again maps the current value', () async {
      final source = _TrackingValueNotifier<int>(1);
      addTearDown(source.dispose);
      final calls = <int, Completer<String>>{};
      final mapped = source.mapValueAsync((it) => (calls[it] = Completer<String>()).future);
      void listener() {}

      mapped.addListener(listener);
      mapped.removeListener(listener);
      calls[1]!.complete('one');
      await _settle();
      expect(source.hasActiveListeners, isFalse);
      expect(mapped.value.hasValue, isFalse);
      expect(mapped.value.isLoading, isFalse);

      source.value = 2;
      mapped.addListener(listener);
      calls[2]!.complete('two');
      await _settle();
      expect(mapped.value.value, 'two');
    });

    testWidgets('ValueListenableBuilder shows a result produced while it subscribes', (tester) async {
      final source = ValueNotifier<int>(4);
      addTearDown(source.dispose);
      final label = source.mapValueAsync((it) => 'v$it').mapValue((it) => it.value ?? '-');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<String>(valueListenable: label, builder: (_, value, _) => Text(value)),
        ),
      );
      await tester.pump();

      expect(find.text('v4'), findsOneWidget);
    });
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _TrackingValueNotifier<T> extends ValueNotifier<T> {
  _TrackingValueNotifier(super.value);

  bool get hasActiveListeners => hasListeners;
}
