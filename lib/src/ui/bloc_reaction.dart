import 'package:uuid/uuid.dart';

int _rid = 0;

class BlocReaction<T> {
  final int reactionId = ++_rid;
  T? _data;
  bool isConsumed = false;

  bool get hasData => _data != null;

  T? peek() => _data;

  BlocReaction([this._data]);

  static BlocReaction<String> generate() => BlocReaction(const Uuid().v1().toString());

  void consume(Function(T?) block) {
    if (isConsumed) {
      return;
    }

    isConsumed = true;
    return block(_data);
  }
}
