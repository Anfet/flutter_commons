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

      source.stream.throttle(duration).listen(
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

      source.stream.debounce(duration).listen(
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
  });
}
