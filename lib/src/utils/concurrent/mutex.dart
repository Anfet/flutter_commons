import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// A simple async mutex that serializes access to critical sections.
class Mutex {
  /// Queue of active and waiting lock holders.
  final List<Completer> completers = [];

  /// Runs [future] exclusively after previous locks are completed.
  Future<T> lock<T>(Future<T> Function() future) async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }

    assert(completers.isEmpty || completers.allOf((it) => it.isCompleted));
    final completer = Completer<T>();
    completers.add(completer);

    Future<T>.sync(future)
        .then((value) => completer.complete(value), onError: (ex, stack) => completer.completeError(ex, stack))
        .whenComplete(() => completers.remove(completer));
    return completer.future;
  }

  /// Waits until there are no active lock owners.
  Future whileBusy() async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }
  }

  /// Whether the mutex currently has active or queued work.
  bool get isBusy => completers.isNotEmpty;
}
