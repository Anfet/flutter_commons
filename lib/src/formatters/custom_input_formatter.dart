import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import 'text_mask.dart';

/// Text input formatter that masks the input with a `CustomFormatter` pattern.
///
/// The edit is applied to the value without the mask: typed and pasted characters fill the placeholders, Backspace or
/// Delete over a literal erases the neighbouring character, and the caret stays at the edit. When the old text was not
/// produced by this formatter (for example set by the app), the new text is formatted from scratch.
class CustomInputFormatter extends TextInputFormatter {
  final String pattern;
  final bool stripPlaceholdersIfNoText;
  final bool backwards;

  CustomInputFormatter({required this.pattern, this.stripPlaceholdersIfNoText = false, this.backwards = false});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text == newValue.text) {
      return newValue;
    }

    final mask = TextMask(pattern, stripPlaceholdersIfNoText: stripPlaceholdersIfNoText);
    // Backwards masks are handled as forward ones over reversed text; the caret is mirrored back at the end.
    final directed = backwards ? mask.reversed : mask;
    final old = _directedChars(oldValue.text);
    final next = _directedChars(newValue.text);
    final oldPayload = directed.extract(old);

    final List<String> payload;
    final int caret;
    if (!listEquals(directed.format(oldPayload).chars, old)) {
      payload = directed.extract(next);
      caret = backwards ? 0 : payload.length;
    } else {
      final newCaret = _directedCaret(newValue.selection, next);
      var prefix = 0;
      final maxPrefix = min(min(old.length, next.length), newCaret ?? next.length);
      while (prefix < maxPrefix && old[prefix] == next[prefix]) {
        prefix++;
      }
      var suffix = 0;
      final maxSuffix = min(min(old.length, next.length) - prefix, next.length - (newCaret ?? prefix));
      while (suffix < maxSuffix && old[old.length - 1 - suffix] == next[next.length - 1 - suffix]) {
        suffix++;
      }

      final removedEnd = old.length - suffix;
      final start = directed.placeholdersBefore(prefix);
      final end = directed.placeholdersBefore(removedEnd);
      final insertedText = next.sublist(prefix, next.length - suffix);
      // Text that replaces the whole value may be raw or formatted; text inserted after a slot is aligned to that slot.
      var inserted = prefix == 0 && suffix == 0 ? directed.extract(insertedText) : directed.extractAt(insertedText, prefix);
      inserted = inserted.take(max(0, directed.capacity - oldPayload.length + end - start)).toList();
      final edited = [...oldPayload]..replaceRange(start, end, inserted);

      if (start == end && inserted.isEmpty && removedEnd > prefix) {
        // Only literals were erased: erase the character beyond them, as Backspace or Delete would.
        final oldCaret = _directedCaret(oldValue.selection, old);
        final isDelete = oldCaret == (backwards ? removedEnd : prefix);
        final index = isDelete == backwards ? start - 1 : start;
        if (index >= 0 && index < edited.length) {
          edited.removeAt(index);
        }
        payload = edited;
        // In both directions the caret ends where the erased character was.
        caret = index.clamp(0, edited.length);
      } else {
        payload = edited;
        caret = backwards ? start : start + inserted.length;
      }
    }

    final masked = directed.format(payload);
    final chars = backwards ? masked.chars.reversed.toList() : masked.chars;
    final offset = backwards ? chars.length - masked.before(caret) : masked.after(caret);
    return TextEditingValue(
      text: chars.join(),
      selection: TextSelection.collapsed(offset: chars.take(offset).join().length),
    );
  }

  List<String> _directedChars(String text) {
    final chars = text.characters.toList();
    return backwards ? chars.reversed.toList() : chars;
  }

  /// Grapheme index of a collapsed [selection] in [directedChars], or `null` for a range or no selection.
  int? _directedCaret(TextSelection selection, List<String> directedChars) {
    if (!selection.isValid || !selection.isCollapsed) {
      return null;
    }
    var index = 0;
    var units = 0;
    final chars = backwards ? directedChars.reversed : directedChars;
    for (final char in chars) {
      if (units >= selection.baseOffset) {
        break;
      }
      units += char.length;
      index++;
    }
    return backwards ? directedChars.length - index : index;
  }
}
