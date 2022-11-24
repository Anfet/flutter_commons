import 'package:uuid/uuid.dart';

int _rid = 0;

class BlocReaction<T> {
  final int reactionId = ++_rid;
  final T _data;

  bool _isConsumed = false;

  bool get isConsumed => _isConsumed;

  T get data => _data;

  BlocReaction(this._data);

  void consume(Function(T argument) block) {
    try {
      if (!_isConsumed) {
        block(data);
      }
    } finally {
      _isConsumed = true;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlocReaction && runtimeType == other.runtimeType && reactionId == other.reactionId;

  @override
  int get hashCode => reactionId.hashCode;

  @override
  String toString() {
    return 'BlocReaction{reactionId: $reactionId, _data: $_data, _isConsumed: $_isConsumed}';
  }

  static BlocReaction<String> generate() => BlocReaction(const Uuid().v1().toString());
}
