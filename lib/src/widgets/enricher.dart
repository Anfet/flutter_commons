import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef TextEnricherSpanBuilder = InlineSpan Function(String text);

/// Public class TextEnricher.
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

      var from = lText.indexOf(lSubtext);
      while (from != -1) {
        splitter.add(from, from + subtext.length, [spanBuilder]);
        from = lText.indexOf(lSubtext, from + lSubtext.length);
      }
    }

    for (var i = 0; i < splitter.ranges.length; i++) {
      final range = splitter.ranges[i];

      final part = text.substring(range.from, range.till);
      final spanBuilder = range.listOfData.whereType<TextEnricherSpanBuilder>().lastOrNull;
      yield range.listOfData.isEmpty ? TextSpan(text: part, style: style) : spanBuilder?.call(part) ?? TextSpan(text: part, style: style);
    }
  }
}
