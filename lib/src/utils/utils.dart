import 'dart:async';
import 'package:flutter_commons/src/exceptions.dart';

/// Returns [obj] if it is not null, otherwise throws [RequireException].
T require<T>(T? obj) {
  if (obj == null) {
    throw RequireException('required obj (${T.runtimeType}) is null');
  }

  return obj;
}

/// Returns [obj] or an empty iterable when null.
Iterable<T> nonEmpty<T>(Iterable<T>? obj) {
  return obj ?? [];
}

/// Public class RequireException.
class RequireException extends AppException {
  RequireException(super.message);
}

/// Executes [block], measures elapsed time, and reports it through [onComplete].
FutureOr<T> runTimed<T>(FutureOr<T> Function() block, void Function(Duration duration) onComplete) async {
  final watch = Stopwatch()..start();
  try {
    return await block();
  } finally {
    watch.stop(); 
    onComplete(watch.elapsed);
  }
}
