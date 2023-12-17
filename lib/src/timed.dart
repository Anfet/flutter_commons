import 'dart:async';

FutureOr<T> runTimed<T>(FutureOr<T> Function() block, void Function(Duration duration) onComplete) async {
  final watch = Stopwatch()..start();
  try {
    return await block();
  } finally {
    onComplete(watch.elapsed);
    watch.stop();
  }
}
