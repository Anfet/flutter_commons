import 'package:flutter_commons/src/functions.dart';
import 'package:flutter_commons/src/randomizer.dart';

int _rid = 0;

typedef StringReaction = BlocReaction<String>;

typedef ShotReaction = BlocReaction<dynamic>;

class BlocReaction<T> {
  final int reactionId = ++_rid;

  final T _data;

  bool _isConsumed = false;

  bool get isConsumed => _isConsumed;

  T get data => _data;

  BlocReaction(this._data);

  void consume(TypedCallback<T> block) {
    try {
      if (!_isConsumed) {
        block(_data);
      }
    } finally {
      _isConsumed = true;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlocReaction && runtimeType == other.runtimeType && reactionId == other.reactionId;

  @override
  int get hashCode => reactionId.hashCode;

  @override
  String toString() {
    return 'BlocReaction{reactionId: $reactionId, _data: $_data, _isConsumed: $_isConsumed}';
  }

  static ShotReaction fire() => ShotReaction(randomizer.nextDouble());
}

extension StringAsReactionExt on String {
  StringReaction get asReaction => StringReaction(this);
}

extension ObjectAsReactionExt<T> on T {
  BlocReaction<T> get asReaction => BlocReaction(this);
}
