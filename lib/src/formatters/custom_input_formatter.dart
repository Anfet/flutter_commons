import 'package:flutter/services.dart';
import 'package:flutter_commons/src/extensions/string_ext.dart';

import '../formatters/custom_formatter.dart';

/// Public class CustomInputFormatter.
class CustomInputFormatter extends TextInputFormatter {
  final String pattern;
  final bool stripPlaceholdersIfNoText;
  final bool backwards;

  CustomInputFormatter({required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Backwards formatting keeps the trailing characters, so input beyond the pattern is cut here to keep the current
    // value. Forward formatting is bounded by the pattern itself and must see the whole text, e.g. a paste with spaces.
    final text = backwards ? newValue.text.take(pattern.length) : newValue.text;
    // A plain deletion stays unformatted so that separators can be erased; a replaced selection is still formatted.
    final formatted = !backwards && newValue.text._isDeletionOf(oldValue.text)
        ? text
        : CustomFormatter(text: text, pattern: pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText, backwards: backwards).formatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

extension on String {
  /// Whether this text is [previous] with one contiguous range removed.
  bool _isDeletionOf(String previous) {
    if (length >= previous.length) {
      return false;
    }
    var prefix = 0;
    while (prefix < length && this[prefix] == previous[prefix]) {
      prefix++;
    }
    return previous.endsWith(substring(prefix));
  }
}
