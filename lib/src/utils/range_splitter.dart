class RangeSplitter {
  final List<SplitterRange> _ranges = [];

  List<SplitterRange> get ranges => _ranges;

  RangeSplitter.init(int from, int till, List<Object?> listOfData) {
    _ranges.add(SplitterRange(from, till, listOfData));
  }

  void add(int from, int till, List<Object?> listOfData) {
    var range = SplitterRange(from, till, listOfData);

    final min = _ranges.first.from;
    final max = _ranges.last.till;

    if (range.till < min) {
      _ranges.insert(0, range);
      if (_ranges[1].listOfData.isEmpty) {
        //растягиваем
        _ranges[1] = _ranges[1].copyWith(from: range.till);
      } else {
        var middle = SplitterRange(range.till, min, []);
        _ranges.insert(1, middle);
      }
      return;
    }

    if (range.from > max) {
      if (_ranges.last.listOfData.isEmpty) {
        var replace = _ranges.last.copyWith(till: range.from);
        _ranges[_ranges.length - 1] = replace;
      } else {
        var middle = SplitterRange(_ranges.last.till, range.from, []);
        _ranges.add(middle);
      }

      _ranges.add(range);
      return;
    }

    var idx = -1;
    while (++idx < _ranges.length) {
      var r = _ranges[idx];
      if (!r.intersectsWith(range)) {
        continue;
      }

      if (range.from > r.from) {
        //мы пересекаем после начала
        var prefix = SplitterRange(r.from, range.from, r.listOfData);
        _ranges[idx] = prefix;
        r = SplitterRange(range.from, r.till, r.listOfData);
        _ranges.insert(idx + 1, r);
        continue;
      }

      if (range.from < r.from) {
        //начало раньше
        var prefix = SplitterRange(range.from, r.from, range.listOfData);
        _ranges.insert(idx - 1, prefix);
        range = range.copyWith(from: r.from);
        continue;
      }

      if (range.till < r.till) {
        //конец входит в предыдущий ренж
        var prefix = SplitterRange(range.from, range.till, r.listOfData + range.listOfData);
        var suffix = SplitterRange(range.till, r.till, r.listOfData);
        _ranges[idx] = prefix;
        _ranges.insert(idx + 1, suffix);
        continue;
      }

      if (range.till > r.till) {
        var prefix = SplitterRange(r.from, r.till, r.listOfData + range.listOfData);
        range = SplitterRange(r.till, range.till, range.listOfData);
        _ranges[idx] = prefix;
        continue;
      }

      if (range.from == r.from && range.till == r.till) {
        _ranges[idx] = range;
      }
    }
  }
}

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
  }) =>
      SplitterRange(from ?? this.from, till ?? this.till, listOfData ?? this.listOfData);

  SplitterRange(this.from, this.till, [this.listOfData = const []]);

  @override
  String toString() {
    return 'SplitterRange{from: $from, till: $till, listOfData: $listOfData}';
  }
}
