import 'dart:math';

import 'package:flutter_commons/src/exceptions.dart';

class StringSource {
  int _pos = 0;
  final String text;
  final bool backwards;

  StringSource(this.text, {this.backwards = false}) {
    if (backwards) {
      _pos = text.length - 1;
    }
  }

  String get value => text;

  String get remaining => backwards ? text.substring(0, _pos + 1) : text.substring(_pos);

  String get peek => hasMore ? text[_pos] : "";

  bool get hasMore => remaining.isNotEmpty;

  int get position => _pos;

  void rewind() => _pos = backwards ? (text.length - 1) : 0;

  String get _nextChar => text[backwards ? _pos-- : _pos++];

  String consume({int count = 1}) {
    final takeAmount = min(count, remaining.length);
    if (takeAmount < 0) {
      throw IllegalArgumentException("take count must be >= 0");
    } else if (takeAmount == 0) {
      return "";
    } else if (takeAmount == 1) {
      return _nextChar;
    }

    String result;
    if (backwards) {
      result = text.substring(text.length - 1 - takeAmount, text.length - 1);
      _pos -= takeAmount;
      return result;
    } else {
      result = text.substring(_pos, takeAmount);
      _pos += takeAmount;
    }
    return result;
  }

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
