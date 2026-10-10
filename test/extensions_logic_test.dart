import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Mode { fast, slow }

void main() {
  group('AnyExt', () {
    test('let, use, takeIf, takeUnless and takeIfIs', () {
      expect(2.let((it) => it * 2), 4);
      expect(5.use((it) => it + 1), 5);
      expect(5.takeIf((it) => it > 3), 5);
      expect(5.takeIf((it) => it > 9), isNull);
      expect(5.takeUnless((it) => it > 3), isNull);
      expect(5.takeUnless((it) => it > 9), 5);
      expect(<Object>[1, 'a'].map((it) => it.takeIfIs<String>()), [null, 'a']);
    });
  });

  group('EnumByName', () {
    test('byNameOr falls back on unknown and null names', () {
      expect(_Mode.values.byNameOr('slow', _Mode.fast), _Mode.slow);
      expect(_Mode.values.byNameOr('nope', _Mode.fast), _Mode.fast);
      expect(_Mode.values.byNameOr(null, _Mode.slow), _Mode.slow);
    });
  });

  group('SetExt and MapImploder', () {
    test('set operators and toggle return new sets', () {
      final set = {1, 2};
      expect(set + [3], {1, 2, 3});
      expect(set - [1], {2});
      expect(set.toggle(1), {2});
      expect(set.toggle(3), {1, 2, 3});
      expect(set, {1, 2});
    });

    test('join skips empty keys and values unless asked', () {
      final map = {'a': '1', 'b': '', '': '3'};
      expect(map.join(), 'a=1');
      expect(map.join(addEmptyValues: true, separator: '&', keyValueSeparator: ':'), 'a:1&b:&:3');
    });
  });

  group('StringExt', () {
    test('take returns the head, the tail for negative counts and clamps', () {
      expect('abcdef'.take(2), 'ab');
      expect('abcdef'.take(-2), 'ef');
      expect('abc'.take(10), 'abc');
      expect('abc'.take(-10), 'abc');
      expect('abc'.take(0), '');
    });

    test('parsing helpers', () {
      expect(['true', 'TRUE', '1', '7', '0', '-1', 'yes', ''].map((it) => it.toBoolOrFalse()), [true, true, true, true, false, false, false, false]);
      expect('12'.toInt(), 12);
      expect('x'.toInt(ifNull: 5), 5);
      expect('1.5'.tryDouble(), 1.5);
      expect('x'.tryInt(), isNull);
    });

    test('cleaning helpers', () {
      expect('a1b2-3'.onlyNumbers, '123');
      expect('+7 (900) 123-45'.stripInvalidCharsForPhoneNumber, '790012345');
      expect('a\r\nb\n'.stripNewLines, 'ab');
      expect(' '.takeIfNotEmpty(), isNull);
      expect(' a '.takeIfNotEmpty(), ' a ');
      expect(''.ifEmpty('x'), 'x');
      expect('abc'.capFirstLetter(), 'Abc');
      expect(''.capFirstLetter(), '');
    });

    test('charAt and setChar address grapheme clusters', () {
      expect('a\u{1F44D}\u{1F3FD}b'.charAt(1), '\u{1F44D}\u{1F3FD}');
      expect('a\u{1F44D}\u{1F3FD}b'.setChar(1, 'x'), 'axb');
      expect('abc'.setChar(0, 'x'), 'xbc');
    });

    test('ensureLength pads on the right and never truncates', () {
      expect('ab'.ensureLength(4, fillChar: '0'), 'ab00');
      expect('abcd'.ensureLength(2), 'abcd');
    });

    test('isValidEmail accepts ordinary addresses and rejects malformed ones', () {
      expect(['a@b.co', ' a.b+c@d-e.org ', 'x_y@mail.example.com'].every((it) => it.isValidEmail), isTrue);
      expect(['', ' ', 'a', 'a@b', 'a@b.c', '@b.com', 'a b@c.com', 'a@b@c.com'].any((it) => it.isValidEmail), isFalse);
    });
  });

  group('Duration extensions', () {
    test('hhmmss omits hours below one hour and does not wrap past a day', () {
      expect(const Duration(seconds: 5).hhmmss, '00:05');
      expect(const Duration(minutes: 61, seconds: 1).hhmmss, '01:01:01');
      expect(const Duration(hours: 25, seconds: 1).hhmmss, '25:00:01');
    });

    test('int helpers build durations', () {
      expect(2.weeks, const Duration(days: 14));
      expect(1.hours + 30.minutes, const Duration(minutes: 90));
      expect(500.milliseconds, const Duration(milliseconds: 500));
    });

    test('division truncates to milliseconds', () {
      expect(const Duration(seconds: 1) / 4, const Duration(milliseconds: 250));
    });
  });

  group('DateTime extensions', () {
    test('between is inclusive', () {
      final a = DateTime(2025, 1, 1);
      final b = DateTime(2025, 1, 3);
      expect([a, DateTime(2025, 1, 2), b].every((it) => it.between(a, b)), isTrue);
      expect(DateTime(2025, 1, 4).between(a, b), isFalse);
      expect(a.isSameOrAfter(a) && a.isSameOrBefore(a), isTrue);
    });

    test('month helpers in a month without a daylight-saving change', () {
      final date = DateTime(2025, 2, 10, 15, 30);
      expect(date.daysInMonth, 28);
      expect(date.startOfTheMonth, DateTime(2025, 2, 1));
      expect(date.endOfTheMonth, DateTime(2025, 2, 28));
      expect(date.stripTime, DateTime(2025, 2, 10));
      expect(date.nextDay, DateTime(2025, 2, 11, 15, 30));
      expect(date.differenceInMonth(DateTime(2024, 11, 1)), 3);
      expect(DateTime(2024, 2, 1).daysInMonth, 29);
    });

    test('addMonths crosses year boundaries in both directions', () {
      final date = DateTime(2025, 3, 15);
      expect(date.addMonths(14), DateTime(2026, 5, 15));
      expect(date.addMonths(-14), DateTime(2024, 1, 15));
      expect(date.addMonths(0), date);
    });
  });

  group('IterableExt', () {
    test('predicates, counting and aggregation', () {
      final values = [1, 2, 3, 4];
      expect(values.anyOf((it) => it > 3), isTrue);
      expect(values.allOf((it) => it > 1), isFalse);
      expect(values.count(), 4);
      expect(values.count((it) => it.isEven), 2);
      expect(values.sumOf(), 10);
      expect(values.maxOf(), 4);
      expect(values.minOf(), 1);
      expect(<int>[].maxOf(null, 7), 7);
      expect(values.filter((it) => it.isOdd), [1, 3]);
      expect(values.firstOr((it) => it > 9, -1), -1);
      expect(values.firstIf((it) => it > 2), 3);
      expect(values.isFirst(1) && values.isLast(4), isTrue);
    });

    test('type filters and forEachUntil', () {
      final values = <Object>[1, 'a', 2];
      expect(values.filterIfIs<int>(), [1, 2]);
      expect(values.filterIfIsNot<int>(), ['a']);
      final seen = <int>[];
      [1, 2, 3].forEachUntil((it) {
        seen.add(it);
        return it == 2;
      });
      expect(seen, [1, 2]);
    });

    test('async mapping keeps order and runs sequentially', () async {
      final log = <String>[];
      final result = await [1, 2, 3].mapListAsync((it) async {
        log.add('start $it');
        await Future<void>.delayed(Duration(milliseconds: 10 * (4 - it)));
        log.add('end $it');
        return it * 2;
      });
      expect(result, [2, 4, 6]);
      expect(log, ['start 1', 'end 1', 'start 2', 'end 2', 'start 3', 'end 3']);
    });
  });

  group('ListExt', () {
    test('non-mutating helpers return new lists', () {
      final list = [1, 2, 3, 4];
      expect(list.toggle(2), [1, 3, 4]);
      expect(list.toggle(9), [1, 2, 3, 4, 9]);
      expect(list.replaceIf((it) => it.isEven, 0), [1, 0, 3, 0]);
      expect(list.replaceIf((it) => it.isEven, 0, false), [1, 0, 3, 4]);
      expect(list.replaceWith((it) => it > 2, (old) => old * 10, replaceAll: false), [1, 2, 30, 4]);
      expect(list.addOrReplace(9, (it) => it == 3), [1, 2, 9, 4]);
      expect(list.addOrReplace(9, (it) => it == 7), [1, 2, 3, 4, 9]);
      expect(list.removeIf((it) => it.isOdd), [2, 4]);
      expect(list.tryAdd(null), list);
      expect(list.tryAdd(5), [1, 2, 3, 4, 5]);
      expect(list.swap(0, 3), [4, 2, 3, 1]);
      expect(list.replaceAt(1, (old) => old + 100), [1, 102, 3, 4]);
      expect(list.mapIndexed((i, v) => i * v), [0, 2, 6, 12]);
      expect(list, [1, 2, 3, 4]);
    });

    test('sorting helpers', () {
      final list = ['bb', 'a', 'cc', 'b'];
      expect(list.sortedBy((a, b) => a.length.compareTo(b.length)).first.length, 1);
      expect(list.multiSortBy([(a, b) => a.length.compareTo(b.length), (a, b) => a.compareTo(b)]), ['a', 'b', 'bb', 'cc']);
    });

    test('splitBy chunks and keeps the remainder', () {
      expect([1, 2, 3, 4, 5].splitBy(2), [
        [1, 2],
        [3, 4],
        [5],
      ]);
      expect(<int>[].splitBy(3), isEmpty);
    });

    test('randomIndex rejects an empty list', () {
      expect(() => <int>[].randomIndex, throwsStateError);
      expect([1, 2, 3].randomIndex, inInclusiveRange(0, 2));
    });
  });

  group('Number extensions', () {
    test('asSigned, between and isZero', () {
      expect([2.asSigned, 0.asSigned, (-2).asSigned], ['+2', '0', '-2']);
      expect(5.between(1, 10), isTrue);
      expect(5.between(5, 10), isFalse);
      expect(0.000001.isZero && !0.01.isZero, isTrue);
    });

    test('int and double helpers', () {
      expect([2.kb, 1.mb], [2048, 1048576]);
      expect([3.descending, 3.desc, 0.toBool(), 2.toBool()], [-3, -3, false, true]);
      expect([2.0.isInt, 2.5.isInt, 2.0.asIntOrNull, 2.5.asIntOrNull], [true, false, 2, null]);
      expect(2.75.fraction, closeTo(0.75, 1e-9));
      expect(180.0.asRadians, closeTo(3.14159265, 1e-6));
      expect(2.78.truncFraction(1), 2.7);
    });
  });

  group('Future extensions', () {
    test('iterable futures proxy to the awaited value', () async {
      Future<Iterable<int>> values() async => [3, 1, 2];
      expect(await values().toList(), [3, 1, 2]);
      expect(await values().filter((it) => it > 1), [3, 2]);
      expect(await values().mapList((it) async => it * 2), [6, 2, 4]);
      expect(await values().first, 3);
      expect(await values().last, 2);
      expect(await Future.value(<int>[]).firstOrNull, isNull);
    });

    test('ifNull awaits the fallback only when the value is null', () async {
      expect(await Future<int?>.value(null).ifNull(Future.value(4)), 4);
      expect(await Future<int?>.value(1).ifNull(Future.value(4)), 1);
    });

    test('map futures proxy keys, values and entry conversion', () async {
      Future<Map<String, int>> map() async => {'a': 1};
      expect(await map().keys, ['a']);
      expect(await map().values, [1]);
      expect(await map().map((k, v) => MapEntry(v, k)), {1: 'a'});
    });
  });

  group('Widget and context extensions', () {
    testWidgets('expanded, global key accessors and scheduleOnNextFrame', (tester) async {
      final key = GlobalKey<_ProbeState>();
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return Column(children: [_Probe(key: key).expanded]);
            },
          ),
        ),
      );

      expect(captured.size, MediaQuery.sizeOf(captured));
      expect(captured.padding, MediaQuery.paddingOf(captured));
      expect(captured.viewInsets, MediaQuery.viewInsetsOf(captured));
      expect(captured.viewPaddings, MediaQuery.viewPaddingOf(captured));
      expect(find.byType(Expanded), findsOneWidget);
      expect(key.requireState, isA<_ProbeState>());
      expect(key.requireWidget, isA<_Probe>());
      expect(key.requireContext, key.currentContext);

      key.requireState.scheduleOnNextFrame(() => key.requireState.ran = true);
      expect(key.requireState.ran, isFalse);
      await tester.pump();
      expect(key.requireState.ran, isTrue);
    });

    testWidgets('routeArguments reads the current route settings', (tester) async {
      final arguments = <String?, Object?>{};
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) {
              arguments[settings.name] = context.routeArguments;
              return const SizedBox();
            },
          ),
          initialRoute: '/x',
        ),
      );
      expect(arguments['/x'], isNull);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed('/y', arguments: 42));
      await tester.pumpAndSettle();
      expect(arguments['/y'], 42);
    });
  });

  group('regressions', () {
    test('toDouble defaults to zero', () {
      expect('x'.toDouble(), 0.0);
    });

    test('truncFraction ignores float representation error', () {
      expect([0.29.truncFraction(2), 4.35.truncFraction(2), 1.999.truncFraction(2), -0.29.truncFraction(2)], [0.29, 4.35, 1.99, -0.29]);
    });

    test('isInt tolerates error on both sides and rejects non-finite values', () {
      expect([434.99999999999994.isInt, 435.00000000000006.isInt, double.nan.isInt, double.infinity.isInt], [true, true, false, false]);
      expect(434.99999999999994.asIntOrNull, 435);
    });

    test('maxOf, minOf and sumOf honour test for numeric elements', () {
      final values = [1, 2, 3];
      expect([values.maxOf((it) => -it), values.minOf((it) => -it), values.sumOf((it) => it * 10)], [-1, -3, 60]);
      expect(() => ['a'].sumOf(), throwsArgumentError);
    });

    test('randomLightColor keeps every channel light', () {
      for (var i = 0; i < 500; i++) {
        final color = randomLightColor;
        expect([color.r, color.g, color.b].every((it) => it * 255 >= 127.5), isTrue);
      }
    });

    test('weeksInMonth matches the calendar rows of every month', () {
      for (var year = 2020; year <= 2031; year++) {
        for (var month = 1; month <= 12; month++) {
          final first = DateTime(year, month, 1);
          final rows = <int>{for (var day = 1; day <= first.daysInMonth; day++) (day + first.weekday - 2) ~/ 7};
          expect(first.weeksInMonth, rows.length, reason: '$year-$month');
        }
      }
    });

    test('date helpers keep time of day and clamp the day', () {
      expect(DateTime(2025, 1, 31, 8, 30).nextMonth, DateTime(2025, 2, 28, 8, 30));
      expect(DateTime(2024, 1, 31).addMonths(1), DateTime(2024, 2, 29));
      expect(DateTime(2025, 1, 8, 15, 30).startOfTheWeek, DateTime(2025, 1, 6, 15, 30));
      expect(DateTime(2025, 3, 30, 12).startOfTheWeek, DateTime(2025, 3, 24, 12));
      expect(DateTime(2025, 3, 31).endOfTheMonth, DateTime(2025, 3, 31));
      expect(DateTime(2025, 1, 1).endOfTheDay, DateTime(2025, 1, 1, 23, 59, 59, 999));
      expect(DateTime.utc(2025, 1, 31).addMonths(1).isUtc, isTrue);
    });

    test('reversed keeps grapheme clusters intact', () {
      expect('a\u{1F44D}\u{1F3FD}b'.reversed, 'b\u{1F44D}\u{1F3FD}a');
    });

    test('splitBy returns independent chunks', () {
      final source = [1, 2, 3];
      source.splitBy(2).first.add(9);
      expect(source, [1, 2, 3]);
    });

    test('join skips null values and Duration division rejects a zero divider', () {
      expect({'a': null, 'b': 1}.join(), 'b=1');
      expect(() => const Duration(seconds: 1) / 0.0, throwsArgumentError);
    });

    test('random helpers reject an empty collection with StateError', () {
      expect(() => <int>[].randomElement, throwsStateError);
      expect(() => <int>[].takeRandom(), throwsStateError);
      expect(<int>[].randomOrNull, isNull);
    });

    testWidgets('scheduleOnNextFrame is skipped once the state is unmounted', (tester) async {
      final key = GlobalKey<_ProbeState>();
      await tester.pumpWidget(_Probe(key: key));
      final state = key.requireState;
      state.scheduleOnNextFrame(() => state.ran = true);
      await tester.pumpWidget(const SizedBox());
      expect(state.ran, isFalse);
    });
  });

  group('Color extensions', () {
    test('random colors are opaque except the semi-transparent one', () {
      expect(randomColor.a, 1.0);
      expect(randomLightColor.a, 1.0);
      expect(randomSemiTransparentColor.a, closeTo(30 / 255, 1e-9));
      expect(Colors.red.filter, ColorFilter.mode(Colors.red, BlendMode.srcIn));
    });
  });
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool ran = false;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
