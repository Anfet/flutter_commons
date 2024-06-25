import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_core/src/data/lib/cancellable.dart';

typedef ListenableValueMapper<T> = FutureOr<Any> Function(T value);
mixin BlocListenables<S, E> on Bloc<S, E> {
  final List<Cancellable> _subscriptions = [];

  /// подписывается на поток и вызывает [mapper] при каждом эмите
  /// Если [mapper] возвращает [false], то слушание будет трервано
  Cancellable onStreamChange<T>(Stream<T> stream, ListenableValueMapper<T> mapper) {
    final cancellable = StreamCancellable(stream, mapper);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  Cancellable onValueChanged<T>(ValueListenable<T> listenable, ListenableValueMapper<T> mapper) {
    final cancellable = ListenableCancellable(listenable, mapper);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  Cancellable onAnyChange(ChangeNotifier notifier, AsyncOrTypedResult<Any> mapper) {
    final cancellable = NotifierCancellable(notifier, mapper);
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
