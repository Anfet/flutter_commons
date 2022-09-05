import 'dart:math';

import 'package:flutter/material.dart';

extension StringExt on String {
  String get onlyNumbers => RegExp("[0-9]").allMatches(this).map((e) => substring(e.start, e.end)).join("");

  String take(int chars) {
    return substring(0, min(chars, length));
  }

  bool toBoolOrFalse() {
    if (toLowerCase() == "true") return true;
    final val = int.tryParse(this);
    if (val != null && val > 0) return true;
    return false;
  }

  String capFirstLetter() => replaceRange(0, 1, this[0].toUpperCase());

  String get stripInvalidCharsForPhoneNumber => replaceAll(RegExp('[ +\\-()]'), '');
  String get stripNewLines => replaceAll(r"\n", "");

  String trimSplash() => replaceAll("/", "");

  String charAt(int index) => characters.characterAt(index).first;

  String setChar(int index, String char) =>
      characters.take(index).string + char + characters.getRange(index + 1).string;
}

extension NullStringExt on String? {
  String get orEmpty => this == null ? "" : this!;
}
