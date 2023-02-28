import 'package:flutter/material.dart';

extension SiberitanDateTimeExt on DateTime {
  bool isSameOrAfter(DateTime other) => this.millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  bool isSameOrBefore(DateTime other) => this.millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  DateTime operator +(Duration duration) => this.add(duration);

  DateTime operator -(Duration duration) => this.subtract(duration);

  DateTime get startOfTheWeek => subtract(Duration(days: this.weekday));

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  DateTime get stripTime => DateTime(year, month, day, 0, 0, 0, 0, 0);
}
