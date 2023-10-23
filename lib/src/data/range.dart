class Range<T> {
  final T? from;
  final T? till;

  const Range([this.from, this.till]);

  const Range.from({this.from, this.till});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Range && runtimeType == other.runtimeType && from == other.from && till == other.till;

  @override
  int get hashCode => from.hashCode ^ till.hashCode;

  @override
  String toString() {
    return 'Range{from: $from, till: $till}';
  }

  T get requireFrom => from!;

  T get requireTill => till!;
}
