import 'dart:math';

import 'package:flutter/material.dart';

import '../data/data.dart';

extension SiberitanDateTimeExt on DateTime {
  bool isSameOrAfter(DateTime other) => millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  bool isSameOrBefore(DateTime other) => millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  DateTime operator +(Duration duration) => add(duration);

  DateTime operator -(Duration duration) => subtract(duration);

  /// Monday of this week, keeping the time of day.
  DateTime get startOfTheWeek => _copy(day: day - (weekday - 1));

  DateTime get startOfTheMonth => DateTime(year, month, 1);

  /// Midnight of the last day of this month.
  DateTime get endOfTheMonth => DateTime(year, month, daysInMonth);

  /// The last millisecond of this day.
  DateTime get endOfTheDay => DateTime(year, month, day + 1).subtract(const Duration(milliseconds: 1));

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  DateTime get stripTime => DateTime(year, month, day, 0, 0, 0, 0, 0);

  bool between(DateTime a, DateTime b) => isSameOrAfter(a) && isSameOrBefore(b);

  bool betweenRange(Range<DateTime> range) => isSameOrAfter(range.requireFrom) && isSameOrBefore(range.requireTill);

  DateTime get nextMonth => addMonths(1);

  DateTime get nextDay => _copy(day: day + 1);

  int differenceInMonth(DateTime other) {
    var yearDiff = year - other.year;
    var monthDiff = month - other.month;
    return yearDiff * 12 + monthDiff;
  }

  /// The number of calendar rows (weeks starting on Monday) this month touches.
  int get weeksInMonth => ((startOfTheMonth.weekday - 1) + daysInMonth + 6) ~/ 7;

  /// Moves by [amount] months, clamping the day to the target month's length and keeping the time of day.
  DateTime addMonths(int amount) {
    final index = year * 12 + (month - 1) + amount;
    final targetYear = index ~/ 12;
    final targetMonth = index % 12 + 1;
    return _copy(year: targetYear, month: targetMonth, day: min(day, DateUtils.getDaysInMonth(targetYear, targetMonth)));
  }

  DateTime _copy({int? year, int? month, int? day}) {
    final y = year ?? this.year;
    final m = month ?? this.month;
    final d = day ?? this.day;
    return isUtc
        ? DateTime.utc(y, m, d, hour, minute, second, millisecond, microsecond)
        : DateTime(y, m, d, hour, minute, second, millisecond, microsecond);
  }
}
