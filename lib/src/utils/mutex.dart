import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class Mutex {
  final List<Completer> completers = [];

  Future<T> lock<T>(Future<T> Function() future) async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }

    assert(completers.isEmpty || completers.allOf((it) => it.isCompleted));
    completers.add(Completer<T>());
    try {
      return await future();
    } finally {
      completers.removeLast().complete();
    }
  }

  Future future() async {
    while (completers.isNotEmpty) {
      await completers.first.future;
    }
  }
}
