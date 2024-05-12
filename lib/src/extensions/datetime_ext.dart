import 'package:flutter/material.dart';

import '../data/lib/range.dart';

extension SiberitanDateTimeExt on DateTime {
  bool isSameOrAfter(DateTime other) => millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  bool isSameOrBefore(DateTime other) => millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  DateTime operator +(Duration duration) => add(duration);

  DateTime operator -(Duration duration) => subtract(duration);

  DateTime get startOfTheWeek => subtract(Duration(days: weekday - 1));

  DateTime get startOfTheMonth => DateTime(year, month, 1).stripTime;

  DateTime get endOfTheMonth => DateTime(year, month, 1).stripTime.add(Duration(days: daysInMonth - 1));

  DateTime get endOfTheDay => DateTime(year, month, day, 23, 59, 59, 0, 0);

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  DateTime get stripTime => DateTime(year, month, day, 0, 0, 0, 0, 0);

  bool between(DateTime a, DateTime b) => isSameOrAfter(a) && isSameOrBefore(b);

  bool betweenRange(Range<DateTime> range) => isSameOrAfter(range.requireFrom) && isSameOrBefore(range.requireTill);

  DateTime get nextMonth => DateTime(year, month + 1, day);

  DateTime get nextDay => DateTime(year, month, day + 1);

  int differenceInMonth(DateTime other) {
    var yearDiff = year - other.year;
    var monthDiff = month - other.month;
    return yearDiff * 12 + monthDiff;
  }

  int get weeksInMonth {
    var start = startOfTheMonth.startOfTheWeek;
    var startOfNextMonth = nextMonth.startOfTheMonth;
    var end = DateTime(startOfNextMonth.year, startOfNextMonth.month, startOfNextMonth.day + 6);
    var weeks = end.difference(start).inDays ~/ 7;
    return weeks;
  }

  DateTime addMonths(int amount) {
    var years = amount ~/ 12;
    var months = amount;
    months -= years * 12;
    var time = DateTime(year + years, month + months, day);
    return time;
  }
}
