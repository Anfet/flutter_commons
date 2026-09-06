import 'dart:async';

import 'package:flutter/widgets.dart';
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

  group('TextStyleExt', () {
    test('weight helpers preserve existing behavior without optical size', () {
      const style = TextStyle(fontVariations: [FontVariation('wdth', 80)]);

      final result = style.bold();

      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontVariations, style.fontVariations);
    });

    test('weight helpers apply optical size as opsz variation', () {
      final result = const TextStyle().w700(opticalSize: 14);

      expect(result.fontWeight, FontWeight.w700);
      expect(result.fontVariations, [const FontVariation('opsz', 14)]);
    });

    test('optical size replaces opsz and preserves other variations', () {
      const style = TextStyle(
        fontVariations: [
          FontVariation('wdth', 80),
          FontVariation('opsz', 10),
          FontVariation('slnt', -5),
        ],
      );

      final result = style.extraBold(opticalSize: 18);

      expect(result.fontVariations, [
        const FontVariation('wdth', 80),
        const FontVariation('opsz', 18),
        const FontVariation('slnt', -5),
      ]);
    });

    test('all named weight helpers accept optical size', () {
      final styles = [
        const TextStyle().medium(opticalSize: 12),
        const TextStyle().normal(opticalSize: 12),
        const TextStyle().thin(opticalSize: 12),
        const TextStyle().w100(opticalSize: 12),
        const TextStyle().w200(opticalSize: 12),
        const TextStyle().w300(opticalSize: 12),
        const TextStyle().w400(opticalSize: 12),
        const TextStyle().w500(opticalSize: 12),
        const TextStyle().w600(opticalSize: 12),
        const TextStyle().w800(opticalSize: 12),
        const TextStyle().w900(opticalSize: 12),
      ];

      expect(
        styles,
        everyElement(
          predicate<TextStyle>((style) {
            return style.fontVariations!.single.value == 12 && style.fontVariations!.single.axis == 'opsz';
          }),
        ),
      );
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

    test('splitBy rejects zero and negative amounts', () {
      final values = [1, 2, 3];

      expect(() => values.splitBy(0), throwsArgumentError);
      expect(() => values.splitBy(-1), throwsArgumentError);
    });

    test('take counts reject negative amounts and preserve zero behavior', () {
      final values = [1, 2, 3];

      expect(values.takeCount(0), isEmpty);
      expect(values.takeLastCount(0), isEmpty);
      expect(() => values.takeCount(-1), throwsArgumentError);
      expect(() => values.takeLastCount(-1), throwsArgumentError);
    });

    test('take counts remove the requested items from either end', () {
      final values = ['a', 'b', 'c', 'd'];

      expect(values.takeCount(2, remove: true), ['a', 'b']);
      expect(values, ['c', 'd']);

      expect(values.takeLastCount(1, remove: true), ['d']);
      expect(values, ['c']);
    });

    test('extract validates amount and from at runtime', () {
      final values = [1, 2, 3];

      expect(() => values.extract(-1), throwsArgumentError);
      expect(() => values.extract(1, from: -1), throwsArgumentError);
      expect(() => values.extract(1, from: values.length + 1), throwsArgumentError);
    });

    test('extract handles empty and end boundaries without assertions', () {
      final values = [1, 2, 3];

      expect(values.extract(0, from: values.length), isEmpty);
      expect(values.extract(1, from: values.length), isEmpty);
      expect(values, [1, 2, 3]);
      expect(<int>[].extract(0), isEmpty);
    });

    test('extract stops at the end for an oversized amount', () {
      final values = [1, 2, 3];

      expect(values.extract(10, from: 1), [2, 3]);
      expect(values, [1]);
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

  group('FutureExt', () {
    test('atLeast waits before returning an early result', () async {
      final clock = Stopwatch()..start();

      final result = await Future.value('ready').atLeast(30.milliseconds);

      expect(result, 'ready');
      expect(clock.elapsed, greaterThanOrEqualTo(20.milliseconds));
    });

    test('atLeast preserves an error from the source future', () async {
      final error = StateError('failure');

      await expectLater(
        Future<int>.error(error).atLeast(10.milliseconds),
        throwsA(same(error)),
      );
    });

    test('atLeast does not add a delay when the future is already slow', () async {
      final clock = Stopwatch()..start();

      final result = await Future<void>.delayed(25.milliseconds).then((_) => 42).atLeast(5.milliseconds);

      expect(result, 42);
      expect(clock.elapsed, greaterThanOrEqualTo(20.milliseconds));
    });

    test('atLeast accepts zero and negative durations', () async {
      expect(await Future.value(1).atLeast(Duration.zero), 1);
      expect(await Future.value(2).atLeast(-1.milliseconds), 2);
    });
  });

  group('NumericUtils', () {
    test('parses comma and dot decimal input', () {
      final commaController = TextEditingController(text: '1,234');
      final dotController = TextEditingController(text: '1.234');
      addTearDown(commaController.dispose);
      addTearDown(dotController.dispose);

      expect(NumericUtils.calculateEnteredQuantity(commaController), 1.23);
      expect(NumericUtils.calculateEnteredQuantity(dotController), 1.23);
      expect(commaController.text, '1.23');
      expect(dotController.text, '1.23');
    });

    test('removes spaces when formatting entered quantity', () {
      final controller = TextEditingController(text: ' 1 234 ');
      addTearDown(controller.dispose);

      expect(NumericUtils.calculateEnteredQuantity(controller), 1234);
      expect(controller.text, '1234');
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
    });

    test('normalizes negative input to a positive quantity', () {
      final controller = TextEditingController(text: '-1.239');
      addTearDown(controller.dispose);

      expect(NumericUtils.calculateEnteredQuantity(controller), 1.23);
      expect(controller.text, '1.23');
    });

    test('limits excessive integer digits', () {
      final controller = TextEditingController(text: '123456789');
      addTearDown(controller.dispose);

      expect(
        NumericUtils.calculateEnteredQuantity(controller, maxLength: 8),
        12345678,
      );
      expect(controller.text, '12345678');
    });

    test('preserves exact precision and the current selection', () {
      final controller = TextEditingController(text: '1.23');
      controller.selection = const TextSelection.collapsed(offset: 2);
      addTearDown(controller.dispose);

      expect(NumericUtils.calculateEnteredQuantity(controller), 1.23);
      expect(controller.text, '1.23');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    test('truncates excessive fractional precision without losing valid digits', () {
      final controller = TextEditingController(text: '1.234');
      addTearDown(controller.dispose);

      expect(NumericUtils.calculateEnteredQuantity(controller), 1.23);
      expect(controller.text, '1.23');
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
    });

    test('supports zero fractional precision', () {
      final controller = TextEditingController(text: '12.99');
      addTearDown(controller.dispose);

      expect(NumericUtils.calculateEnteredQuantity(controller, maxFraction: 0), 12);
      expect(controller.text, '12');
    });

    test('applies the optional formatter and moves the cursor to its end', () {
      final controller = TextEditingController(text: '1.234');
      addTearDown(controller.dispose);

      expect(
        NumericUtils.calculateEnteredQuantity(controller, onFormat: (text) => '€$text'),
        1.23,
      );
      expect(controller.text, '€1.23');
      expect(controller.selection, const TextSelection.collapsed(offset: 5));
    });

    test('rejects invalid length and precision limits', () {
      final controller = TextEditingController(text: '1.23');
      addTearDown(controller.dispose);

      expect(
        () => NumericUtils.calculateEnteredQuantity(controller, maxLength: 0),
        throwsArgumentError,
      );
      expect(
        () => NumericUtils.calculateEnteredQuantity(controller, maxFraction: -1),
        throwsArgumentError,
      );
    });
  });
}
