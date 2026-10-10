import 'package:flutter/widgets.dart' show StringCharacters;

import 'custom_formatter.dart';

/// Pattern of literal and placeholder slots shared by [CustomFormatter] and `CustomInputFormatter`.
///
/// Works on grapheme clusters, so an emoji fills one [CustomFormatter.anyPlaceholder]. A
/// [CustomFormatter.digitPlaceholder] accepts a digit, an [CustomFormatter.anyPlaceholder] any character, every other
/// pattern character is a literal. Backwards formatting is forward formatting of the [reversed] mask over reversed text.
class TextMask {
  final List<String> slots;
  final bool stripPlaceholdersIfNoText;

  TextMask(String pattern, {this.stripPlaceholdersIfNoText = false}) : slots = pattern.characters.toList();

  TextMask._(this.slots, this.stripPlaceholdersIfNoText);

  TextMask get reversed => TextMask._(slots.reversed.toList(), stripPlaceholdersIfNoText);

  /// Number of placeholders, the most characters a value can hold.
  int get capacity => slots.where(_isPlaceholder).length;

  /// Number of placeholders among the first [slotCount] slots.
  int placeholdersBefore(int slotCount) => slots.take(slotCount).where(_isPlaceholder).length;

  /// Extracts the characters that fill the placeholders of [text], which may be raw or already formatted.
  List<String> extract(List<String> text) {
    final raw = _extract(text, consumeLiterals: false);
    // Formatted text repeats the literals, and so may raw text with more characters than placeholders (a phone number
    // with its country code). Otherwise a literal must not swallow typed input: "7" in "+7 (###)" is the first digit.
    if (!_startsWithLeadingLiterals(text) && !raw.overflow) {
      return raw.payload;
    }
    return _extract(text, consumeLiterals: true).payload;
  }

  /// Extracts [text] inserted at [slot] of a value formatted by this mask.
  List<String> extractAt(List<String> text, int slot) => _extract(text, consumeLiterals: true, fromSlot: slot).payload;

  /// Formats [payload], dropping characters their placeholder rejects and characters beyond [capacity].
  MaskedText format(List<String> payload) {
    final placeholders = slots.where(_isPlaceholder).toList();
    final fitted = <String>[];
    final kept = [0];
    for (final char in payload) {
      if (fitted.length < placeholders.length && _accepts(placeholders[fitted.length], char)) {
        fitted.add(char);
      }
      kept.add(fitted.length);
    }

    final chars = <String>[];
    final starts = <int>[];
    int? firstPlaceholder;
    for (final slot in slots) {
      if (!_isPlaceholder(slot)) {
        // Literals lead the first character unless stripped, but never trail the last one.
        if (starts.length == fitted.length && (fitted.isNotEmpty || stripPlaceholdersIfNoText)) {
          break;
        }
        chars.add(slot);
        continue;
      }
      firstPlaceholder ??= chars.length;
      if (starts.length == fitted.length) {
        break;
      }
      starts.add(chars.length);
      chars.add(fitted[starts.length - 1]);
    }
    return MaskedText._(chars, starts, firstPlaceholder ?? chars.length, kept);
  }

  ({List<String> payload, bool overflow}) _extract(List<String> text, {required bool consumeLiterals, int fromSlot = 0}) {
    final payload = <String>[];
    var slot = fromSlot;
    var index = 0;
    while (index < text.length && slot < slots.length) {
      final char = text[index];
      if (!_isPlaceholder(slots[slot])) {
        if (consumeLiterals && char == slots[slot]) {
          index++;
        }
        slot++;
      } else if (_accepts(slots[slot], char)) {
        payload.add(char);
        index++;
        slot++;
      } else {
        index++;
      }
    }
    return (payload: payload, overflow: index < text.length);
  }

  bool _startsWithLeadingLiterals(List<String> text) {
    final leading = slots.takeWhile((slot) => !_isPlaceholder(slot)).toList();
    if (text.length < leading.length) {
      return false;
    }
    for (var i = 0; i < leading.length; i++) {
      if (text[i] != leading[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _isPlaceholder(String slot) => slot == CustomFormatter.digitPlaceholder || slot == CustomFormatter.anyPlaceholder;

  static bool _accepts(String slot, String char) => slot == CustomFormatter.anyPlaceholder || int.tryParse(char) != null;
}

/// Result of [TextMask.format] with the grapheme offsets of its payload characters.
class MaskedText {
  final List<String> chars;
  final List<int> _starts;
  final int _firstPlaceholder;
  final List<int> _kept;

  MaskedText._(this.chars, this._starts, this._firstPlaceholder, this._kept);

  /// Offset right after the first [count] payload characters passed to [TextMask.format].
  int after(int count) {
    final fitted = _kept[count];
    return fitted == 0 ? _firstPlaceholder : _starts[fitted - 1] + 1;
  }

  /// Offset of the payload character with index [count] passed to [TextMask.format], or the end of the text.
  int before(int count) {
    final fitted = _kept[count];
    return fitted < _starts.length ? _starts[fitted] : chars.length;
  }
}
