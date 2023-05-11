import 'dart:async';

import 'package:siberian_core/src/functions.dart';

mixin StreamListenableMixin {
  final List<StreamSubscription> _subscriptions = [];

  void onValueChanged<T extends Object>(Stream<T> stream, TypedCallback<T> onChange) {
    _subscriptions.add(stream.listen(onChange));
  }

  Future<void> removeListeners() async {
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
  }
}
