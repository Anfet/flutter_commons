import 'package:flutter/services.dart';
import 'package:flutter_commons/src/extensions/string_ext.dart';

import '../formatters/custom_formatter.dart';

class CustomInputFormatter extends TextInputFormatter {
  final String pattern;
  final bool stripPlaceholdersIfNoText;
  final bool backwards;

  CustomInputFormatter({required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final somethingWasDeleted = oldValue.text.length > newValue.text.length;
    var subbed;
    if (newValue.text.length < pattern.length) {
      var padded = backwards ? newValue.text.padLeft(pattern.length) : newValue.text.padRight(pattern.length);
      subbed = backwards ? padded.substring(pattern.length - newValue.text.length - 1, pattern.length) : padded.substring(0, pattern.length);
    } else {
      subbed = newValue.text.take(pattern.length);
    }

    var text = subbed.trim();
    String formatted = somethingWasDeleted && !backwards
        ? text
        : CustomFormatter(text: text, pattern: pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText, backwards: backwards).formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
