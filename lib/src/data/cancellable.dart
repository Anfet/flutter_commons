import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/src/functions.dart';

abstract interface class Cancellable {
  void cancel();
}

class StreamCancellable<T> implements Cancellable {
  final Stream<T> stream;
  final AsyncOrTypedCallback<Any, T> mapper;
  late final StreamSubscription subscription;

  StreamCancellable(this.stream, this.mapper) {
    subscription = stream.asyncMap((event) async {
      var shouldContinue = await mapper(event);
      if (shouldContinue == false) {
        cancel();
      }
    }).listen(null);
  }

  @override
  void cancel() => subscription.cancel();
}

class NotifierCancellable implements Cancellable {
  static int _eid = 0;
  final ChangeNotifier notifier;
  final StreamController<int> _streamController = StreamController();
  final AsyncOrTypedResult<Any> mapper;

  NotifierCancellable(this.notifier, this.mapper) {
    notifier.addListener(_mapper);
    _streamController.stream.asyncMap((event) async {
      var shouldContinue = await mapper();
      if (shouldContinue == false) {
        cancel();
      }
    }).listen(null);
    _mapper();
  }

  @override
  void cancel() {
    notifier.removeListener(_mapper);
    _streamController.close();
  }

  void _mapper() {
    _streamController.add(++_eid);
  }
}

class ListenableCancellable<T> implements Cancellable {
  final ValueListenable<T> listenable;
  final StreamController<T> _streamController = StreamController();
  final AsyncOrTypedCallback<Any, T> mapper;

  ListenableCancellable(this.listenable, this.mapper) {
    listenable.addListener(_mapper);
    _streamController.stream.asyncMap((event) async {
      var shouldContinue = await mapper(event);
      if (shouldContinue == false) {
        cancel();
      }
    }).listen(null);
    _mapper();
  }

  @override
  void cancel() {
    listenable.removeListener(_mapper);
    _streamController.close();
  }

  void _mapper() {
    _streamController.add(listenable.value);
  }
}
