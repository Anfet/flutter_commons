import 'package:flutter/cupertino.dart';

@immutable
class Pair<A, B> {
  final A? first;
  final B? second;

  A get requireFirst => first!;

  B get requireSecond => second!;

  A get a => requireFirst;

  B get b => requireSecond;

  A? get maybeA => first;

  B? get maybeB => second;

  const Pair(this.first, this.second);

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
