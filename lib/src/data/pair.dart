import 'package:flutter/cupertino.dart';

@immutable
/// Immutable tuple of two values.
///
/// Both values are nullable and can be accessed via [first]/[second] or
/// aliases [a]/[b].
class Pair<A, B> {
  /// First value.
  final A? first;

  /// Second value.
  final B? second;

  /// Non-null accessor for [first].
  A get requireFirst => first!;

  /// Non-null accessor for [second].
  B get requireSecond => second!;

  /// Alias for [requireFirst].
  A get a => requireFirst;

  /// Alias for [requireSecond].
  B get b => requireSecond;

  /// Nullable alias for [first].
  A? get maybeA => first;

  /// Nullable alias for [second].
  B? get maybeB => second;

  /// Creates pair from positional values.
  const Pair(this.first, this.second);

  /// Creates pair from named values.
  const Pair.from({this.first, this.second});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pair && runtimeType == other.runtimeType && first == other.first && second == other.second;

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() {
    return 'Pair{first: $first, second: $second}';
  }
}
