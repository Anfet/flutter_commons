import 'dart:async';

FutureOr<T> runTimed<T>(FutureOr<T> Function() block, void Function(Duration duration) onComplete) async {
  final a = DateTime.now();
  try {
    return await block();
  } finally {
    final b = DateTime.now();
    onComplete(b.difference(a));
  }
}
