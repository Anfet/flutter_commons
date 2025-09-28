import 'dart:async';
import 'package:flutter_commons/src/exceptions.dart';

T require<T>(T? obj) {
  if (obj == null) {
    throw RequireException('required obj is null');
  }

  return obj;
}

Iterable<T> nonEmpty<T>(Iterable<T>? obj) {
  return obj ?? [];
}

class RequireException extends AppException {
  RequireException(super.message);
}

FutureOr<T> runTimed<T>(FutureOr<T> Function() block, void Function(Duration duration) onComplete) async {
  final watch = Stopwatch()..start();
  try {
    return await block();
  } finally {
    onComplete(watch.elapsed);
    watch.stop();
  }
}
