import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class Mutex {
  final List<Completer> completers = [];

  Future<T> lock<T>(Future<T> Function() future) async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }

    assert(completers.isEmpty || completers.allOf((it) => it.isCompleted));
    final completer = Completer<T>();
    completers.add(completer);

    future()
        .then((value) => completer.complete(value), onError: (ex, stack) => completer.completeError(ex, stack))
        .whenComplete(() => completers.remove(completer));
    return completer.future;
  }

  Future whileBusy() async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }
  }

  bool get isBusy => completers.isNotEmpty;
}
