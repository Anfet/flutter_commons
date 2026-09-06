/// Splits and merges overlapping integer ranges with associated payload data.
class RangeSplitter {
  final List<SplitterRange> _ranges = [];

  List<SplitterRange> get ranges => _ranges;

  RangeSplitter.init(int from, int till, List<Object?> listOfData) {
    _ranges.add(SplitterRange(from, till, listOfData));
  }

  /// Adds a range and merges payloads in intersection segments.
  void add(int from, int till, List<Object?> listOfData) {
    final range = SplitterRange(from, till, listOfData);
    final boundaries = <int>{from, till};
    for (final existing in _ranges) {
      boundaries.add(existing.from);
      boundaries.add(existing.till);
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final result = <SplitterRange>[];
    for (var i = 0; i < sortedBoundaries.length - 1; i++) {
      final segmentFrom = sortedBoundaries[i];
      final segmentTill = sortedBoundaries[i + 1];
      if (segmentFrom == segmentTill) {
        continue;
      }

      final segmentData = <Object?>[];
      for (final existing in _ranges) {
        if (existing.from <= segmentFrom && existing.till >= segmentTill) {
          segmentData.addAll(existing.listOfData);
        }
      }
      if (range.from <= segmentFrom && range.till >= segmentTill) {
        segmentData.addAll(range.listOfData);
      }
      result.add(SplitterRange(segmentFrom, segmentTill, segmentData));
    }
    _ranges
      ..clear()
      ..addAll(result);
  }
}

/// A half-open integer range `[from, till)` with associated payload list.
class SplitterRange {
  final int from;
  final int till;
  final List<Object?> listOfData;

  bool intersectsWith(SplitterRange other) => !(from >= other.till || till <= other.from);

  bool canConsume(SplitterRange other) => from <= other.from && till >= other.till;

  SplitterRange copyWith({
    int? from,
    int? till,
    List<Object?>? listOfData,
  }) => SplitterRange(from ?? this.from, till ?? this.till, listOfData ?? this.listOfData);

  SplitterRange(this.from, this.till, [this.listOfData = const []]);

  @override
  String toString() {
    return 'SplitterRange{from: $from, till: $till, listOfData: $listOfData}';
  }
}
