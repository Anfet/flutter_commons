import 'package:flutter_commons/src/consts.dart';
import 'package:flutter_commons/src/data/string_source.dart';

class CustomFormatter {
  static const digitPlaceholder = '#';
  static const anyPlaceholder = '_';

  final String text;
  final String pattern;
  final bool stripPlaceholdersIfNoText;

  ///starts parsing from end characters. usefull for numbers
  final bool backwards;

  late final _textSource = StringSource(text, backwards: backwards);
  late final _patternSource = StringSource(pattern, backwards: backwards);

  CustomFormatter({required this.text, required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  String get formatted => _format();

  String _format() {
    String formatted = "";

    while (_patternSource.hasMore) {
      var char = _patternSource.consume();
      final patternLetter = _PatternLetter(character: char, pattern: char.pattern);

      if (patternLetter.pattern == _Pattern.direct) {
        if (_textSource.peek == patternLetter.character) {
          _textSource.consume();
        }

        if (!_textSource.hasMore && stripPlaceholdersIfNoText) {
          break;
        }

        if (backwards) {
          formatted = patternLetter.character + formatted;
        } else {
          formatted += patternLetter.character;
        }
      } else if (patternLetter.pattern == _Pattern.digit) {
        while (_textSource.hasMore) {
          final sourceLetter = _textSource.consume();
          final int? digit = int.tryParse(sourceLetter);
          if (digit == null) {
            continue;
          }
          if (backwards) {
            formatted = "$digit$formatted";
          } else {
            formatted += "$digit";
          }

          break;
        }

        if (!_textSource.hasMore) {
          break;
        }
      } else if (patternLetter.pattern == _Pattern.any) {
        final any = _textSource.consume();
        if (any == Strings.empty) {
          break;
        }
        if (backwards) {
          formatted = any + formatted;
        } else {
          formatted += any;
        }
      }
    }

    return formatted;
  }
}

class _PatternLetter {
  final String character;
  final _Pattern pattern;

  _PatternLetter({
    required this.character,
    required this.pattern,
  });

  @override
  String toString() {
    return '_PatternLetter{character: $character, pattern: $pattern}';
  }
}

enum _Pattern {
  direct,
  digit,
  any,
}

extension _StringToPatternExt on String {
  _Pattern get pattern {
    if (this == CustomFormatter.anyPlaceholder) return _Pattern.any;
    if (this == CustomFormatter.digitPlaceholder) return _Pattern.digit;
    return _Pattern.direct;
  }
}
