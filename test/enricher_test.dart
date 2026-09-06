import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_commons/flutter_commons.dart';

void main() {
  TextEnricherSpanBuilder builder(Color color) =>
      (text) => TextSpan(
        text: text,
        style: TextStyle(color: color),
      );

  test('enriches every non-overlapping occurrence', () {
    final spans = TextEnricher.enrich(
      text: 'go go go',
      subtexts: {'go': builder(Colors.red)},
    ).toList();

    expect(spans.map((span) => (span as TextSpan).text), ['go', ' ', 'go', ' ', 'go']);
    expect(spans.where((span) => (span as TextSpan).style?.color == Colors.red), hasLength(3));
  });

  test('uses the later insertion for exact overlapping ranges', () {
    final spans = TextEnricher.enrich(
      text: 'abc',
      subtexts: {
        'ab': builder(Colors.red),
        'AB': builder(Colors.blue),
      },
    ).toList();

    expect((spans[0] as TextSpan).text, 'ab');
    expect((spans[0] as TextSpan).style?.color, Colors.blue);
    expect((spans[1] as TextSpan).text, 'c');
  });

  test('uses the later insertion on a contained overlap', () {
    final spans = TextEnricher.enrich(
      text: 'abcd',
      subtexts: {
        'abc': builder(Colors.red),
        'b': builder(Colors.blue),
      },
    ).toList();

    expect((spans[0] as TextSpan).text, 'a');
    expect((spans[0] as TextSpan).style?.color, Colors.red);
    expect((spans[1] as TextSpan).text, 'b');
    expect((spans[1] as TextSpan).style?.color, Colors.blue);
    expect((spans[2] as TextSpan).text, 'c');
    expect((spans[2] as TextSpan).style?.color, Colors.red);
  });

  test('preserves insertion precedence for partial overlaps', () {
    final spans = TextEnricher.enrich(
      text: 'abcd',
      subtexts: {
        'ab': builder(Colors.red),
        'bc': builder(Colors.blue),
      },
    ).toList();

    expect((spans[0] as TextSpan).text, 'a');
    expect((spans[0] as TextSpan).style?.color, Colors.red);
    expect((spans[1] as TextSpan).text, 'b');
    expect((spans[1] as TextSpan).style?.color, Colors.blue);
    expect((spans[2] as TextSpan).text, 'c');
    expect((spans[2] as TextSpan).style?.color, Colors.blue);
    expect((spans[3] as TextSpan).text, 'd');
  });

  test('can be reused without retaining previous ranges', () {
    final first = TextEnricher.enrich(text: 'one', subtexts: {'one': builder(Colors.red)}).toList();
    final second = TextEnricher.enrich(text: 'two', subtexts: {'two': builder(Colors.blue)}).toList();

    expect((first.single as TextSpan).style?.color, Colors.red);
    expect((second.single as TextSpan).style?.color, Colors.blue);
  });
}
