import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef TextEnricherSpanBuilder = InlineSpan Function(String text);

class TextEnricher {
  TextEnricher._();

  static Iterable<InlineSpan> enrich({
    required String text,
    required Map<String, TextEnricherSpanBuilder?> subtexts,
    TextStyle? style,
  }) sync* {
    final lText = text.toLowerCase();
    final splitter = RangeSplitter.init(0, text.length, []);

    final entries = subtexts.entries.toList();
    for (var i = 0; i < subtexts.length; i++) {
      final subtext = entries[i].key;
      final spanBuilder = entries[i].value;
      final lSubtext = subtext.toLowerCase();
      if (lSubtext.isEmpty) {
        continue;
      }

      final from = lText.indexOf(lSubtext);
      final to = from + subtext.length;
      if (from == -1 || to == -1) {
        continue;
      }

      splitter.add(from, to, [spanBuilder]);
    }

    if (splitter.ranges.length == 1) {
      yield TextSpan(text: text, style: style);
      return;
    }

    for (var i = 0; i < splitter.ranges.length; i++) {
      final range = splitter.ranges[i];
      if (range.listOfData.length > 1) {
        throw IllegalArgumentException('bad list of data for range: $range');
      }

      final part = text.substring(range.from, range.till);
      final spanBuilder = range.listOfData.firstOrNull as TextEnricherSpanBuilder?;
      yield range.listOfData.isEmpty ? TextSpan(text: part, style: style) : spanBuilder?.call(part) ?? TextSpan(text: part, style: style);
    }
  }
}
