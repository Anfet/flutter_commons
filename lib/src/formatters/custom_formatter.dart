

import 'package:siberian_core/src/consts.dart';
import 'package:siberian_core/src/data/lib/string_source.dart';
import 'package:siberian_core/src/extensions/any_ext.dart';

class CustomFormatter {
  static const digitPlaceholder = '#';
  static const anyPlaceholder = '_';

  final String text;
  final String pattern;
  late final _patternSource = StringSource(pattern);
  late final _textSource = StringSource(text);
  final bool stripPlaceholdersIfNoText;

  CustomFormatter({required this.text, required this.pattern, this.stripPlaceholdersIfNoText = false});

  String get formatted => _format();

  String _format() {
    String formatted = "";

    while (_patternSource.hasMore) {
      final patternLetter = _patternSource.consume().let(
            (it) => _PatternLetter(
              character: it,
              pattern: it.pattern,
            ),
          );

      if (patternLetter.pattern == _Pattern.direct) {
        if (_textSource.peek == patternLetter.character) {
          _textSource.consume();
        }

        if (!_textSource.hasMore && stripPlaceholdersIfNoText) {
          break;
        }

        formatted += patternLetter.character;
      } else if (patternLetter.pattern == _Pattern.digit) {
        final sourceLetter = _textSource.consume();
        final int? digit = int.tryParse(sourceLetter);
        if (digit == null) {
          break;
        }
        formatted += "$digit";
      } else if (patternLetter.pattern == _Pattern.any) {
        final any = _textSource.consume();
        if (any == Strings.empty) {
          break;
        }
        formatted += any;
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
