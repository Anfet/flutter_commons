import 'package:flutter/widgets.dart' show StringCharacters;

import 'text_mask.dart';

/// Public class CustomFormatter.
class CustomFormatter {
  static const digitPlaceholder = '#';
  static const anyPlaceholder = '_';

  final String text;
  final String pattern;
  final bool stripPlaceholdersIfNoText;

  ///starts parsing from end characters. usefull for numbers
  final bool backwards;

  CustomFormatter({required this.text, required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  String get formatted {
    final mask = TextMask(pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText);
    final directed = backwards ? mask.reversed : mask;
    final chars = text.characters.toList();
    final result = directed.format(directed.extract(backwards ? chars.reversed.toList() : chars)).chars;
    return (backwards ? result.reversed : result).join();
  }
}
