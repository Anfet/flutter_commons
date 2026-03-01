import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

extension CompleterExt<T> on Completer<T> {
  Completer<T> fromFuture(Future<T> future) {
    future.then(
      (value) {
        if (!isCompleted) {
          complete(value);
        }
      },
      onError: (error, stackTrace) {
        if (!isCompleted) {
          completeError(error ?? FlowException("No error on error"), stackTrace);
        }
      },
    );
    return this;
  }
}
