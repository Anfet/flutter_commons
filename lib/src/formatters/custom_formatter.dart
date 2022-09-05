import '../consts.dart';
import '../data/string_source.dart';
import '../extensions/any_ext.dart';

class CustomFormatter {
  static const digitPlaceholder = '#';
  static const anyPlaceholder = '_';

  final String text;
  final String pattern;
  late final _patternSource = StringSource(pattern);
  late final _textSource = StringSource(text);

  CustomFormatter({required this.text, required this.pattern});

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
        formatted += patternLetter.character;
      } else if (patternLetter.pattern == _Pattern.digit) {
        final int? digit = int.tryParse(_textSource.consume());
        if (digit == null) {
          break;
        }
        formatted += "$digit";
      } else if (patternLetter.pattern == _Pattern.any) {
        final any = _textSource.consume();
        if (any == empty) {
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
