import 'package:flutter/material.dart';

import '../data/range.dart';

extension SiberitanDateTimeExt on DateTime {
  bool isSameOrAfter(DateTime other) => this.millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  bool isSameOrBefore(DateTime other) => this.millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  DateTime operator +(Duration duration) => this.add(duration);

  DateTime operator -(Duration duration) => this.subtract(duration);

  DateTime get startOfTheWeek => subtract(Duration(days: this.weekday - 1));

  DateTime get startOfTheMonth => DateTime(year, month, 1).stripTime;

  DateTime get endOfTheMonth => DateTime(year, month, 1).stripTime.add(Duration(days: daysInMonth - 1));

  DateTime get endOfTheDay => DateTime(year, month, day, 23, 59, 59, 0, 0);

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  DateTime get stripTime => DateTime(year, month, day, 0, 0, 0, 0, 0);

  bool between(DateTime a, DateTime b) => isSameOrAfter(a) && isSameOrBefore(b);

  bool betweenRange(Range<DateTime> range) => isSameOrAfter(range.requireFrom) && isSameOrBefore(range.requireTill);
}
