import 'package:flutter/cupertino.dart';

class TextEnricher {
  TextEnricher._();

  static Iterable<InlineSpan> enrich({required String text, required String subtext, TextStyle? style, required TextStyle enrichedStyle}) sync* {
    var lText = text.toLowerCase();
    var lSubtext = subtext.toLowerCase();
    if (subtext.isEmpty || !lText.contains(lSubtext)) {
      yield TextSpan(text: text, style: style);
      return;
    }

    var from = lText.indexOf(lSubtext);
    var to = from + subtext.length;

    var parts = [text.substring(0, from), text.substring(from, to), text.substring(to)];
    if (parts[0].isNotEmpty) {
      yield TextSpan(text: parts[0], style: style);
    }

    if (parts[1].isNotEmpty) {
      yield TextSpan(text: parts[1], style: enrichedStyle);
    }

    if (parts[2].isNotEmpty) {
      yield TextSpan(text: parts[2], style: style);
    }
  }
}
