import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_core/src/data/lib/cancellable.dart';

mixin BlocListenables on Bloc {
  final List<Cancellable> _subscriptions = [];

  Cancellable onStreamChange<T>(Stream<T> stream, Future<bool?> Function(T value) block) {

    final cancellable = StreamCancellable(stream, block);
    _subscriptions.add(cancellable);
    return cancellable;
  }


  Cancellable onValueChanged<T>(ValueListenable<T> listenable, Future<bool?> Function(T value) block) {
    final cancellable = ListenableCancellable(listenable, block);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  Cancellable onAnyChange(ChangeNotifier notifier, Future<bool?> Function() block) {
    final cancellable = NotifierCancellable(notifier, block);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  @override
  Future<void> close() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    return super.close();
  }
}
