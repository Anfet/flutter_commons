import 'dart:async';

import 'package:siberian_core/siberian_core.dart';

extension CompleterExt<T> on Completer<T> {
  Completer<T> fromFuture(Future<T> future) {
    final completer = Completer<T>();
    future.then((value) => completer.complete(value)).onError(
          (error, stackTrace) => completer.completeError(error ?? FlowException("No error on error"), stackTrace),
        );
    return completer;
  }
}
