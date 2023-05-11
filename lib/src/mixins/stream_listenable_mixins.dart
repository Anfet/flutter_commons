import 'dart:async';

import 'package:siberian_core/src/functions.dart';

mixin StreamListenableMixin {
  final List<StreamSubscription> _subscriptions = [];

  void listenToStream<T extends Object?>(Stream<T> stream, TypedCallback<T> onChange) {
    _subscriptions.add(stream.listen(onChange));
  }

  Future<void> removeStreamListeners() async {
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
  }
}
