import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('debounce EventTransformer', () {
    test('emits only the latest event after debounce duration', () async {
      const duration = Duration(milliseconds: 40);
      final source = StreamController<int>();
      final emitted = <int>[];
      final done = Completer<void>();

      final stream = debounce<int>(duration)(
        source.stream,
        (event) => Stream.value(event),
      );

      stream.listen(
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

      await source.close();
      await done.future;
    });

    test('flushes pending event when source closes before timer fires', () async {
      const duration = Duration(milliseconds: 100);
      final source = StreamController<int>();
      final emitted = <int>[];
      final done = Completer<void>();

      final stream = debounce<int>(duration)(
        source.stream,
        (event) => Stream.value(event),
      );

      stream.listen(
        emitted.add,
        onDone: done.complete,
      );

      source.add(10);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await source.close();
      await done.future;

      expect(emitted, [10]);
    });
  });
}
