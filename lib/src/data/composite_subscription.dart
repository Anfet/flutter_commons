import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class CompositeSubscription implements Closable {
  bool _isClosed = false;

  final List<StreamSubscription> _subscriptions = [];

  void subscribeTo<T>(Stream<T> stream, FutureOr<dynamic> Function(T value) listener) =>
      _subscriptions.add(stream.listen(listener));

  @override
  FutureOr<void> close() async {
    for (final element in _subscriptions) {
      await element.cancel();
    }

    _subscriptions.clear();
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;
}
