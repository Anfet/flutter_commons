import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mutex', () {
    test('lock recovers after synchronous exception', () async {
      final mutex = Mutex();

      await expectLater(
        mutex.lock<int>(() {
          throw StateError('sync failure');
        }),
        throwsA(isA<StateError>()),
      );

      expect(mutex.isBusy, isFalse);

      final value = await mutex.lock(() async => 42);
      expect(value, 42);
    });

    test('runs a queued callback after a synchronous predecessor failure', () async {
      final mutex = Mutex();
      final calls = <int>[];

      final failing = mutex.lock<int>(() {
        calls.add(1);
        throw StateError('sync failure');
      });
      final queued = mutex.lock(() async {
        calls.add(2);
        return 42;
      });

      await expectLater(failing, throwsA(isA<StateError>()));
      expect(await queued, 42);
      expect(calls, [1, 2]);
    });

    test('runs a queued callback after an asynchronous predecessor failure', () async {
      final mutex = Mutex();
      final releaseFirst = Completer<void>();
      final calls = <int>[];

      final failing = mutex.lock<int>(() async {
        calls.add(1);
        await releaseFirst.future;
        throw StateError('async failure');
      });
      final queued = mutex.lock(() async {
        calls.add(2);
        return 42;
      });

      await Future<void>.delayed(Duration.zero);
      expect(calls, [1]);

      releaseFirst.complete();
      await expectLater(failing, throwsA(isA<StateError>()));
      expect(await queued, 42);
      expect(calls, [1, 2]);
    });

    test('runs contenders in FIFO order', () async {
      final mutex = Mutex();
      final firstRelease = Completer<void>();
      final secondRelease = Completer<void>();
      final calls = <int>[];

      final first = mutex.lock(() async {
        calls.add(1);
        await firstRelease.future;
        return 1;
      });
      final second = mutex.lock(() async {
        calls.add(2);
        await secondRelease.future;
        return 2;
      });
      final third = mutex.lock(() async {
        calls.add(3);
        return 3;
      });

      await Future<void>.delayed(Duration.zero);
      expect(calls, [1]);

      firstRelease.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(calls, [1, 2]);

      secondRelease.complete();
      expect(await second, 2);
      expect(await third, 3);
      expect(calls, [1, 2, 3]);
    });

    test('whileBusy waits for queued work without receiving owner errors', () async {
      final mutex = Mutex();
      final releaseFirst = Completer<void>();
      var queuedRan = false;

      final failing = mutex.lock<void>(() async {
        await releaseFirst.future;
        throw StateError('failure');
      });
      final queued = mutex.lock(() async {
        queuedRan = true;
      });
      final waiting = mutex.whileBusy();

      releaseFirst.complete();
      await expectLater(failing, throwsA(isA<StateError>()));
      await waiting;

      expect(queuedRan, isTrue);
      await queued;
      expect(mutex.isBusy, isFalse);
    });
  });

  group('PagedLoader', () {
    test('starts from initialPage and increments next page', () async {
      final requestedPages = <int>[];
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        initialPage: 5,
        onDemand: (page, itemsPerPage, [arguments]) async {
          requestedPages.add(page);
          return [page, page + 1];
        },
      );
      addTearDown(loader.dispose);

      final firstResult = await loader.loadPage();
      final secondResult = await loader.loadPage();

      expect(requestedPages, [5, 6]);
      expect(firstResult, [5, 6]);
      expect(secondResult, [6, 7]);
      expect(loader.lastPageLoaded, 6);
      expect(loader.nextPageToBeLoaded, 7);
      expect(loader.items, [5, 6, 6, 7]);
    });

    test('keeps items ordered by page when pages loaded out of order', () async {
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        initialPage: 0,
        onDemand: (page, itemsPerPage, [arguments]) async => [page * 10 + 1, page * 10 + 2],
      );
      addTearDown(loader.dispose);

      await loader.loadPage(page: 2);
      await loader.loadPage(page: 0);
      await loader.loadPage(page: 1);

      expect(loader.items, [1, 2, 11, 12, 21, 22]);
    });

    test('keeps successful pages readable after a failure and recovers on retry', () async {
      final failure = StateError('page failed');
      final failureStack = StackTrace.current;
      var pageOneAttempts = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) async {
          if (page == 0) {
            return [1, 2];
          }
          if (pageOneAttempts++ == 0) {
            Error.throwWithStackTrace(failure, failureStack);
          }
          return [3, 4];
        },
      );
      addTearDown(loader.dispose);

      await loader.loadPage();
      await expectLater(loader.loadPage(), throwsA(same(failure)));

      expect(loader.items, [1, 2]);
      expect(loader.hasError, isTrue);
      expect(loader.nextPageToBeLoaded, 1);

      expect(await loader.loadPage(), [3, 4]);
      expect(loader.items, [1, 2, 3, 4]);
      expect(loader.hasError, isFalse);
      expect(loader.nextPageToBeLoaded, 2);
    });

    test('emits loading then one terminal state with the original error and stack', () async {
      final failure = StateError('page failed');
      final failureStack = StackTrace.current;
      var attempts = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) async {
          if (attempts++ == 0) {
            Error.throwWithStackTrace(failure, failureStack);
          }
          return [1, 2];
        },
      );
      final states = <Loadable<List<int>>>[];
      final subscription = loader.stream.listen(states.add);
      addTearDown(() async {
        await subscription.cancel();
        loader.dispose();
      });

      await expectLater(loader.loadPage(), throwsA(same(failure)));
      await pumpEventQueue();

      expect(states, hasLength(2));
      expect(states[0].isLoading, isTrue);
      expect(states[0].hasError, isFalse);
      expect(states[0].value, isEmpty);
      expect(states[1].isLoading, isFalse);
      expect(states[1].error, same(failure));
      expect(states[1].stack.toString(), failureStack.toString());
      expect(states[1].value, isEmpty);

      states.clear();
      expect(await loader.loadPage(), [1, 2]);
      await pumpEventQueue();

      expect(states, hasLength(2));
      expect(states[0].isLoading, isTrue);
      expect(states[0].hasError, isFalse);
      expect(states[0].value, isEmpty);
      expect(states[1].isLoading, isFalse);
      expect(states[1].hasError, isFalse);
      expect(states[1].value, [1, 2]);
    });

    test('clear invalidates an in-flight page without disturbing a fresh load', () async {
      final staleResult = Completer<List<int>>();
      final freshResult = Completer<List<int>>();
      var attempts = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) => attempts++ == 0 ? staleResult.future : freshResult.future,
      );
      final states = <Loadable<List<int>>>[];
      final subscription = loader.stream.listen(states.add);
      addTearDown(() async {
        await subscription.cancel();
        loader.dispose();
      });

      final staleLoad = loader.loadPage();
      loader.clear();
      final freshLoad = loader.loadPage();

      freshResult.complete([10, 11]);
      expect(await freshLoad, [10, 11]);
      staleResult.complete([99]);
      expect(await staleLoad, [99]);
      await pumpEventQueue();

      expect(loader.items, [10, 11]);
      expect(loader.didReachEnd, isFalse);
      expect(states, hasLength(4));
      expect(states.map((state) => state.isLoading), [true, false, true, false]);
      expect(states.map((state) => state.value), [
        <int>[],
        null,
        <int>[],
        [10, 11],
      ]);
      expect(states.every((state) => !state.hasError), isTrue);
    });

    test('refreshes a historical page without changing global end detection', () async {
      var pageZeroAttempts = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) async {
          if (page == 0) {
            return pageZeroAttempts++ == 0 ? [1, 2] : [9];
          }
          return [3, 4];
        },
      );
      addTearDown(loader.dispose);

      await loader.loadPage();
      await loader.loadPage();
      expect(loader.didReachEnd, isFalse);

      expect(await loader.loadPage(page: 0), [9]);
      expect(loader.items, [9, 3, 4]);
      expect(loader.didReachEnd, isFalse);
      expect(loader.nextPageToBeLoaded, 2);
    });

    test('detects the end only from a short next page', () async {
      var calls = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) async {
          calls++;
          return page == 0 ? [1, 2] : [3];
        },
      );
      addTearDown(loader.dispose);

      await loader.loadPage();
      expect(loader.didReachEnd, isFalse);
      await loader.loadPage();
      expect(loader.didReachEnd, isTrue);

      expect(await loader.loadPage(), isEmpty);
      expect(calls, 2);
      expect(loader.items, [1, 2, 3]);
    });

    test('refreshes an explicit historical page after reaching the end', () async {
      var pageZeroAttempts = 0;
      var calls = 0;
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) async {
          calls++;
          if (page == 0) {
            return pageZeroAttempts++ == 0 ? [1, 2] : [9];
          }
          return [3];
        },
      );
      addTearDown(loader.dispose);

      await loader.loadPage();
      await loader.loadPage();
      expect(loader.didReachEnd, isTrue);

      expect(await loader.loadPage(page: 0), [9]);
      expect(loader.items, [9, 3]);
      expect(loader.didReachEnd, isTrue);
      expect(loader.nextPageToBeLoaded, 2);

      expect(await loader.loadPage(), isEmpty);
      expect(calls, 3);
    });

    test('dispose invalidates an in-flight page without emitting after close', () async {
      final result = Completer<List<int>>();
      final loader = PagedLoader<int, void>(
        itemsPerPage: 2,
        onDemand: (page, itemsPerPage, [arguments]) => result.future,
      );
      final states = <Loadable<List<int>>>[];
      final subscription = loader.stream.listen(states.add);
      final done = subscription.asFuture<void>();

      final load = loader.loadPage();
      await pumpEventQueue();
      loader.dispose();
      result.complete([1, 2]);

      expect(await load, [1, 2]);
      await done;
      expect(states, hasLength(1));
      expect(states.single.isLoading, isTrue);
      expect(loader.items, isEmpty);
      expect(loader.isLoading, isFalse);
    });
  });

  group('QueryScheduler', () {
    test('retry does not over-increment tries', () async {
      final scheduler = QueryScheduler();
      var attempts = 0;

      final future = scheduler.get<int>(
        () async {
          attempts++;
          throw StateError('fail');
        },
        onFail: (_, __, ___) => QueryRetry.retry,
      );

      await expectLater(future, throwsA(isA<StateError>()));
      expect(attempts, QueryRequest.defaultRetries);
    });

    for (final priority in [QueryPriority.low, QueryPriority.immediate]) {
      group('${priority.name} terminal actions', () {
        for (final action in QueryRetry.values) {
          test('${action.name} completes its request', () async {
            final scheduler = QueryScheduler();
            final originalError = StateError('original ${action.name} failure');
            var attempts = 0;

            final failure = await _queryFailure(
              scheduler
                  .get<int>(
                    () async {
                      attempts++;
                      throw originalError;
                    },
                    priority: priority,
                    onFail: (_, __, ___) => action,
                  )
                  .timeout(const Duration(seconds: 1)),
            );

            switch (action) {
              case QueryRetry.retry:
              case QueryRetry.reschedule:
                expect(attempts, QueryRequest.defaultRetries);
                expect(failure.error, same(originalError));
              case QueryRetry.fail:
                expect(attempts, 1);
                expect(failure.error, same(originalError));
              case QueryRetry.drop:
                expect(attempts, 1);
                expect(failure.error, isA<CancelledQueryException>());
            }
            expect(failure.stack, isNotNull);
          });
        }
      });
    }

    test('reschedule moves a queued request behind its peers without resetting retries', () async {
      final scheduler = QueryScheduler();
      final order = <String>[];
      var attempts = 0;

      final first = scheduler.get<int>(
        () async {
          attempts++;
          order.add('first-$attempts');
          throw StateError('first failure');
        },
        onFail: (_, __, ___) => QueryRetry.reschedule,
      );
      final second = scheduler.get<int>(() async {
        order.add('second');
        return 2;
      });

      await expectLater(first, throwsA(isA<StateError>()));
      expect(await second, 2);
      expect(attempts, QueryRequest.defaultRetries);
      expect(order, ['first-1', 'second', 'first-2', 'first-3']);
    });

    for (final priority in [QueryPriority.low, QueryPriority.immediate]) {
      test('${priority.name} uses an onFail exception as the terminal failure', () async {
        final scheduler = QueryScheduler();
        final callbackError = ArgumentError('onFail failure');

        final failure = await _queryFailure(
          scheduler
              .get<int>(
                () async => throw StateError('request failure'),
                priority: priority,
                onFail: (_, __, ___) => throw callbackError,
              )
              .timeout(const Duration(seconds: 1)),
        );

        expect(failure.error, same(callbackError));
        expect(failure.stack, isNotNull);
      });
    }

    for (final priority in [QueryPriority.low, QueryPriority.immediate]) {
      test('drop cancels an in-flight ${priority.name} request without rescheduling it', () async {
        final scheduler = QueryScheduler();
        final release = Completer<void>();
        var attempts = 0;

        final future = scheduler.get<int>(
          () async {
            attempts++;
            await release.future;
            throw StateError('request failure');
          },
          priority: priority,
          onFail: (_, __, ___) => QueryRetry.reschedule,
        );
        await Future<void>.delayed(Duration.zero);

        scheduler.drop();
        release.complete();

        final failure = await _queryFailure(future.timeout(const Duration(seconds: 1)));
        expect(failure.error, isA<CancelledQueryException>());
        await Future<void>.delayed(Duration.zero);
        expect(attempts, 1);
      });
    }
  });

  group('RangeSplitter', () {
    test('add handles overlap that starts before first range', () {
      final splitter = RangeSplitter.init(10, 20, ['a']);

      expect(() => splitter.add(5, 15, ['b']), returnsNormally);
      expect(splitter.ranges.any((r) => r.from == 5), isTrue);
    });

    test('preserves payloads for an exact range', () {
      final splitter = RangeSplitter.init(10, 20, ['base']);

      splitter.add(10, 20, ['added']);

      expect(splitter.ranges.map((r) => [r.from, r.till, r.listOfData]), [
        [
          10,
          20,
          ['base', 'added'],
        ],
      ]);
    });

    test('splits a contained range and merges payloads', () {
      final splitter = RangeSplitter.init(10, 20, ['base']);

      splitter.add(12, 18, ['inner']);

      expect(splitter.ranges.map((r) => [r.from, r.till, r.listOfData]), [
        [
          10,
          12,
          ['base'],
        ],
        [
          12,
          18,
          ['base', 'inner'],
        ],
        [
          18,
          20,
          ['base'],
        ],
      ]);
    });

    test('splits a containing range and retains both tails', () {
      final splitter = RangeSplitter.init(10, 20, ['base']);

      splitter.add(5, 25, ['outer']);

      expect(splitter.ranges.map((r) => [r.from, r.till, r.listOfData]), [
        [
          5,
          10,
          ['outer'],
        ],
        [
          10,
          20,
          ['base', 'outer'],
        ],
        [
          20,
          25,
          ['outer'],
        ],
      ]);
    });

    test('keeps touching ranges separate', () {
      final splitter = RangeSplitter.init(10, 20, ['base']);

      splitter.add(5, 10, ['before']);
      splitter.add(20, 25, ['after']);

      expect(splitter.ranges.map((r) => [r.from, r.till, r.listOfData]), [
        [
          5,
          10,
          ['before'],
        ],
        [
          10,
          20,
          ['base'],
        ],
        [
          20,
          25,
          ['after'],
        ],
      ]);
    });

    test('keeps disjoint ranges and their gap', () {
      final splitter = RangeSplitter.init(10, 20, ['base']);

      splitter.add(25, 30, ['disjoint']);

      expect(splitter.ranges.map((r) => [r.from, r.till, r.listOfData]), [
        [
          10,
          20,
          ['base'],
        ],
        [20, 25, []],
        [
          25,
          30,
          ['disjoint'],
        ],
      ]);
    });
  });

  group('RangeJoiner', () {
    test('merges overlapping bounded ranges', () {
      final joiner = RangeJoiner<int>(compare: (left, right) => left.compareTo(right));

      joiner.add(const Range.from(from: 10, till: 20));
      joiner.add(const Range.from(from: 15, till: 25));

      expect(joiner.ranges, [const Range.from(from: 10, till: 25)]);
    });

    test('merges touching bounded ranges', () {
      final joiner = RangeJoiner<int>(compare: (left, right) => left.compareTo(right));

      joiner.add(const Range.from(from: 10, till: 20));
      joiner.add(const Range.from(from: 20, till: 30));

      expect(joiner.ranges, [const Range.from(from: 10, till: 30)]);
    });
  });
}

class _QueryFailure {
  final Object error;
  final StackTrace stack;

  const _QueryFailure(this.error, this.stack);
}

Future<_QueryFailure> _queryFailure(Future<Object?> future) async {
  try {
    await future;
    throw StateError('Expected a query failure');
  } catch (error, stack) {
    return _QueryFailure(error, stack);
  }
}
