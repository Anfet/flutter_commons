/// Immutable range with optional lower ([from]) and upper ([till]) bounds.
///
/// This type can represent fully bounded, half-bounded, or open ranges.
class Range<T> {
  /// Lower bound.
  final T? from;

  /// Upper bound.
  final T? till;

  /// Creates range from positional bounds.
  const Range([this.from, this.till]);

  /// Creates range from named bounds.
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

  /// Non-null accessor for [from].
  T get requireFrom => from!;

  /// Non-null accessor for [till].
  T get requireTill => till!;

  /// Whether at least one bound is set.
  bool get hasAnyRange => from != null || till != null;

  /// Whether both bounds are set.
  bool get hasBothRanges => from != null && till != null;
}
