import 'package:flutter_commons/src/data/range.dart';

/// Joins overlapping or touching ranges into a normalized list.
class RangeJoiner<T> {
  final int Function(T left, T right) _compare;
  final List<Range<T>> _ranges = [];

  List<Range<T>> get ranges => _ranges;

  RangeJoiner({required int Function(T left, T right) compare}) : _compare = compare;

  /// Adds a bounded range and merges it with existing overlapping ranges.
  ///
  /// Open-ended ranges are not supported here because joining requires both
  /// bounds to be comparable.
  void add(Range<T> range) {
    final from = range.from;
    final till = range.till;

    if (from == null || till == null) {
      throw ArgumentError.value(range, 'range', 'RangeJoiner supports only bounded ranges');
    }

    if (_compare(from, till) > 0) {
      throw ArgumentError.value(range, 'range', 'range.from must be <= range.till');
    }

    _ranges.add(Range.from(from: from, till: till));
    _ranges.sort(_compareByFrom);

    final merged = <Range<T>>[];
    for (final current in _ranges) {
      if (merged.isEmpty) {
        merged.add(current);
        continue;
      }

      final last = merged.last;
      if (_compare(current.requireFrom, last.requireTill) <= 0) {
        merged[merged.length - 1] = Range.from(
          from: _min(last.requireFrom, current.requireFrom),
          till: _max(last.requireTill, current.requireTill),
        );
      } else {
        merged.add(current);
      }
    }

    _ranges
      ..clear()
      ..addAll(merged);
  }

  int _compareByFrom(Range<T> left, Range<T> right) => _compare(left.requireFrom, right.requireFrom);

  T _min(T left, T right) => _compare(left, right) <= 0 ? left : right;

  T _max(T left, T right) => _compare(left, right) >= 0 ? left : right;
}
