import 'package:flutter/services.dart';

import '../formatters/custom_formatter.dart';

class CustomInputFormatter extends TextInputFormatter {
  final String pattern;
  final bool stripPlaceholdersIfNoText;

  CustomInputFormatter({required this.pattern, this.stripPlaceholdersIfNoText = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final somethingWasDeleted = oldValue.text.length > newValue.text.length;
    final text = newValue.text.padRight(pattern.length).substring(0, pattern.length).trim();
    final formatted =
        somethingWasDeleted ? text : CustomFormatter(text: text, pattern: pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText).formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
