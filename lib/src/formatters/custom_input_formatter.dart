import 'package:flutter/services.dart';
import 'package:flutter_commons/src/extensions/string_ext.dart';

import '../formatters/custom_formatter.dart';

/// Public class CustomInputFormatter.
class CustomInputFormatter extends TextInputFormatter {
  static const String _padChar = '\u0000';

  final String pattern;
  final bool stripPlaceholdersIfNoText;
  final bool backwards;

  CustomInputFormatter({required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final somethingWasDeleted = oldValue.text.length > newValue.text.length;
    String subbed;
    if (newValue.text.length < pattern.length) {
      var padded = backwards ? newValue.text.padLeft(pattern.length, _padChar) : newValue.text.padRight(pattern.length, _padChar);
      subbed = backwards ? padded.substring(pattern.length - newValue.text.length - 1, pattern.length) : padded.substring(0, pattern.length);
    } else {
      subbed = newValue.text.take(pattern.length);
    }

    var text = subbed.replaceAll(_padChar, '');
    String formatted = somethingWasDeleted && !backwards
        ? text
        : CustomFormatter(text: text, pattern: pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText, backwards: backwards).formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
