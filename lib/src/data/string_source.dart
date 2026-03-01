import 'dart:math';

import 'package:flutter_commons/src/exceptions.dart';

/// Cursor-based reader over a string.
///
/// Supports forward and backward traversal, peeking, and consuming characters
/// incrementally.
class StringSource {
  int _pos = 0;

  /// Source text being traversed.
  final String text;

  /// Whether traversal is performed from end to start.
  final bool backwards;

  /// Creates a cursor over [text].
  StringSource(this.text, {this.backwards = false}) {
    if (backwards) {
      _pos = text.length - 1;
    }
  }

  /// Full source text.
  String get value => text;

  /// Remaining part based on current cursor and direction.
  String get remaining => backwards ? text.substring(0, _pos + 1) : text.substring(_pos);

  /// Current character without consuming it.
  String get peek => hasMore ? text[_pos] : "";

  /// Whether there are characters left to consume.
  bool get hasMore => remaining.isNotEmpty;

  /// Current cursor position.
  int get position => _pos;

  /// Resets cursor to the beginning for current direction.
  void rewind() => _pos = backwards ? (text.length - 1) : 0;

  String get _nextChar => text[backwards ? _pos-- : _pos++];

  /// Consumes up to [count] characters from the current cursor position.
  String consume({int count = 1}) {
    if (count < 0) {
      throw IllegalArgumentException("take count must be >= 0");
    }

    final takeAmount = min(count, remaining.length);
    if (takeAmount == 0) {
      return "";
    } else if (takeAmount == 1) {
      return _nextChar;
    }

    String result;
    if (backwards) {
      final endExclusive = _pos + 1;
      final start = endExclusive - takeAmount;
      result = text.substring(start, endExclusive).split('').reversed.join();
      _pos -= takeAmount;
      return result;
    } else {
      result = text.substring(_pos, _pos + takeAmount);
      _pos += takeAmount;
    }
    return result;
  }

  /// Consumes characters until [check] returns true, then returns that character.
  ///
  /// Returns `null` when no matching character was found.
  String? consumeUntil(bool Function(String peek) check) {
    while (hasMore) {
      String peek = _nextChar;
      if (check(peek)) {
        return peek;
      }
    }

    return null;
  }

  @override
  String toString() {
    if (_pos == text.length) {
      return 'StringSource{text: $text<}';
    }

    if (_pos == 0) {
      return 'StringSource{text: >$text}';
    }

    final start = text.substring(0, _pos);
    final end = text.substring(_pos);
    return 'StringSource{text: $start>$end}';
  }
}
