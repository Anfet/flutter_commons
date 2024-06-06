import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siberian_core/src/data/data.dart';

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

extension BlocWaitableEventExt on Bloc {
  Future<T> addAndWait<T>(WaitableEvent<T> event) async {
    add(event);
    return event.completer().future;
  }
}
