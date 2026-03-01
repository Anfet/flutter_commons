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
  });

  group('RangeSplitter', () {
    test('add handles overlap that starts before first range', () {
      final splitter = RangeSplitter.init(10, 20, ['a']);

      expect(() => splitter.add(5, 15, ['b']), returnsNormally);
      expect(splitter.ranges.any((r) => r.from == 5), isTrue);
    });
  });
}
