import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Public mixin WaitableEvent.
mixin WaitableEvent<T> {
  final Lazy<Completer<T>> completer = Lazy(() => Completer<T>());

  void complete([FutureOr<T>? result]) {
    if (!completer().isCompleted) {
      completer().complete(result);
    }
  }

  void fail(Object error, [StackTrace? stack]) {
    if (!completer().isCompleted) {
      completer().completeError(error, stack);
    }
  }
}

extension BlocWaitableEventExt<E extends BlocEvent, S> on Bloc<E, S> {
  Future<T> addAndWait<T>(E event) async {
    if (event is! WaitableEvent<T>) {
      throw IllegalArgumentException('Event $event must implement WaitableEvent<$T>');
    }
    final waitable = event as WaitableEvent<T>;
    add(event);
    return waitable.completer().future;
  }
}
