import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stream transformers', () {
    test('throttle emits leading event and suppresses frequent events', () async {
      const duration = Duration(milliseconds: 40);
      final source = StreamController<int>();
      final emitted = <int>[];
      final done = Completer<void>();

      source.stream
          .throttle(duration)
          .listen(
            emitted.add,
            onDone: done.complete,
          );

      source.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      source.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      source.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 35));
      source.add(4);
      await source.close();
      await done.future;

      expect(emitted, [1, 4]);
    });

    test('debounce emits only after quiet period and flushes on done', () async {
      const duration = Duration(milliseconds: 40);
      final source = StreamController<int>();
      final emitted = <int>[];
      final done = Completer<void>();

      source.stream
          .debounce(duration)
          .listen(
            emitted.add,
            onDone: done.complete,
          );

      source.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      source.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      source.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitted, [3]);

      source.add(4);
      await source.close();
      await done.future;

      expect(emitted, [3, 4]);
    });

    test('throttle emits the first event of each burst', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final subscription = source.stream.throttle(const Duration(milliseconds: 25)).listen(emitted.add);

      source
        ..add(1)
        ..add(2);
      await Future<void>.delayed(const Duration(milliseconds: 35));
      source
        ..add(3)
        ..add(4);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await subscription.cancel();
      await source.close();
      expect(emitted, [1, 3]);
    });

    test('debounce emits the last event in a burst', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final subscription = source.stream.debounce(const Duration(milliseconds: 25)).listen(emitted.add);

      source
        ..add(1)
        ..add(2)
        ..add(3);
      await Future<void>.delayed(const Duration(milliseconds: 35));

      await subscription.cancel();
      await source.close();
      expect(emitted, [3]);
    });

    test('debounce flushes a pending event when upstream is done', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final done = Completer<void>();
      source.stream
          .debounce(const Duration(seconds: 1))
          .listen(
            emitted.add,
            onDone: done.complete,
          );

      source.add(7);
      await source.close();
      await done.future;

      expect(emitted, [7]);
    });

    test('forwards errors without losing debounce state', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final errors = <Object>[];
      final stackTraces = <StackTrace>[];
      final done = Completer<void>();
      source.stream
          .debounce(const Duration(milliseconds: 20))
          .listen(
            emitted.add,
            onError: (Object error, StackTrace stackTrace) {
              errors.add(error);
              stackTraces.add(stackTrace);
            },
            onDone: done.complete,
          );

      source.add(1);
      final expectedStackTrace = StackTrace.current;
      source.addError(StateError('boom'), expectedStackTrace);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await source.close();
      await done.future;

      expect(emitted, [1]);
      expect(errors.single, isA<StateError>());
      expect(stackTraces.single, same(expectedStackTrace));
    });

    test('pause and resume pauses upstream and preserves ordering', () async {
      final upstreamPaused = Completer<void>();
      final source = StreamController<int>(
        onPause: () {
          if (!upstreamPaused.isCompleted) {
            upstreamPaused.complete();
          }
        },
      );
      final emitted = <int>[];
      final subscription = source.stream.throttle(const Duration(milliseconds: 1)).listen(emitted.add);

      subscription.pause();
      await upstreamPaused.future;
      source.add(1);
      subscription.resume();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      source.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await subscription.cancel();
      await source.close();

      expect(emitted, [1, 2]);
    });

    test('cancelling before debounce timer fires produces no late output', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final subscription = source.stream.debounce(const Duration(milliseconds: 40)).listen(emitted.add);

      source.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await subscription.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await source.close();

      expect(emitted, isEmpty);
    });

    test('cancelling before throttle timer fires produces no late output', () async {
      final source = StreamController<int>();
      final emitted = <int>[];
      final subscription = source.stream.throttle(const Duration(milliseconds: 40)).listen(emitted.add);

      source.add(1);
      await subscription.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      source.add(2);
      await source.close();

      expect(emitted, isEmpty);
    });

    test('cancellation cancels the instrumented upstream subscription', () async {
      final sourceCancelled = Completer<void>();
      final source = StreamController<int>(
        onCancel: () {
          sourceCancelled.complete();
        },
      );
      final subscription = source.stream.debounce(const Duration(seconds: 1)).listen((_) {});

      await subscription.cancel();
      await sourceCancelled.future;
      expect(source.isClosed, isFalse);
      await source.close();
    });

    test('cancelOnError preserves the error stack trace and cancels debounce work', () async {
      final sourceCancelled = Completer<void>();
      final source = StreamController<int>(
        onCancel: () {
          sourceCancelled.complete();
        },
      );
      final stackTraces = <StackTrace>[];
      final emitted = <int>[];
      final expectedStackTrace = StackTrace.current;
      source.stream
          .debounce(const Duration(milliseconds: 40))
          .listen(
            emitted.add,
            onError: (Object _, StackTrace stackTrace) => stackTraces.add(stackTrace),
            cancelOnError: true,
          );

      source
        ..add(1)
        ..addError(StateError('boom'), expectedStackTrace);
      await sourceCancelled.future;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await source.close();

      expect(emitted, isEmpty);
      expect(stackTraces.single, same(expectedStackTrace));
    });

    test('same transformed broadcast stream supports repeated independent subscriptions', () async {
      final source = StreamController<int>.broadcast();
      final transformed = source.stream.throttle(const Duration(milliseconds: 20));
      final first = <int>[];
      final second = <int>[];
      final firstSub = transformed.listen(first.add);
      final secondSub = transformed.listen(second.add);

      expect(transformed.isBroadcast, isTrue);

      source.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await firstSub.cancel();
      source.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await secondSub.cancel();
      await source.close();

      expect(first, [1]);
      expect(second, [1, 2]);
    });

    test('throttle closes its gate before synchronous downstream re-entry', () async {
      late void Function(int) emit;
      final source = Stream<int>.multi((controller) {
        emit = controller.addSync;
      });
      final emitted = <int>[];
      final done = Completer<void>();

      source.throttle(const Duration(milliseconds: 20)).listen(
        (event) {
          emitted.add(event);
          if (event == 1) {
            emit(2);
          }
        },
        onDone: done.complete,
      );

      emit(1);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emitted, [1]);
    });

    test('cancelling during synchronous throttle delivery cancels its timer', () async {
      late void Function(int) emit;
      final activeTimers = <Timer>{};
      await runZoned(() async {
        final source = Stream<int>.multi((controller) {
          emit = controller.addSync;
        });
        late StreamSubscription<int> subscription;
        Future<void>? cancellation;
        subscription = source.throttle(const Duration(seconds: 1)).listen((_) {
          cancellation = subscription.cancel();
        });

        emit(1);
        await cancellation;

        expect(activeTimers, isEmpty);
      }, zoneSpecification: _timerTrackingZone(activeTimers));
    });

    test('debounce preserves an event added from its synchronous listener', () async {
      late void Function(int) emit;
      final source = Stream<int>.multi((controller) {
        emit = controller.addSync;
      });
      final emitted = <int>[];

      source.debounce(const Duration(milliseconds: 10)).listen((event) {
        emitted.add(event);
        if (event == 1) {
          emit(2);
        }
      });

      emit(1);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emitted, [1, 2]);
    });

    test('throttle window continues while the output subscription is paused', () async {
      final source = StreamController<int>(sync: true);
      final emitted = <int>[];
      final subscription = source.stream.throttle(const Duration(milliseconds: 20)).listen(emitted.add);

      source.add(1);
      subscription.pause();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      subscription.resume();
      source.add(2);

      await subscription.cancel();
      await source.close();
      expect(emitted, [1, 2]);
    });

    test('zero and negative durations remain asynchronous and do not throw', () async {
      final source = StreamController<int>.broadcast();
      final throttleOutput = <int>[];
      final debounceOutput = <int>[];
      final debounceDone = Completer<void>();
      source.stream.throttle(Duration.zero).listen(throttleOutput.add);
      source.stream
          .debounce(const Duration(microseconds: -1))
          .listen(
            debounceOutput.add,
            onDone: debounceDone.complete,
          );
      source.add(1);
      source.add(2);
      await source.close();
      await debounceDone.future;
      await Future<void>.delayed(Duration.zero);

      expect(throttleOutput, [1]);
      expect(debounceOutput, [2]);
    });
  });
}

ZoneSpecification _timerTrackingZone(Set<Timer> activeTimers) {
  return ZoneSpecification(
    createTimer: (self, parent, zone, duration, callback) {
      late final _TrackedTimer timer;
      timer = _TrackedTimer(
        parent.createTimer(zone, duration, () {
          activeTimers.remove(timer);
          callback();
        }),
        () => activeTimers.remove(timer),
      );
      activeTimers.add(timer);
      return timer;
    },
  );
}

class _TrackedTimer implements Timer {
  final Timer _delegate;
  final void Function() _onCancel;
  var _cancelled = false;

  _TrackedTimer(this._delegate, this._onCancel);

  @override
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _onCancel();
    }
    _delegate.cancel();
  }

  @override
  bool get isActive => _delegate.isActive;

  @override
  int get tick => _delegate.tick;
}
