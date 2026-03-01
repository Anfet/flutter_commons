import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/src/functions.dart';

/// Represents a resource or workflow that can be cancelled.
abstract interface class Cancellable {
  /// Stops further processing and releases any attached listeners/subscriptions.
  void cancel();
}

/// Listens to a [Stream] and maps each event through [mapper].
///
/// If [mapper] returns `false`, this instance cancels its subscription.
class StreamCancellable<T> implements Cancellable {
  /// Source stream to observe.
  final Stream<T> stream;

  /// Callback invoked for each source event.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedCallback<Any, T> mapper;

  /// Active subscription to [stream].
  late final StreamSubscription subscription;

  /// Creates a cancellable stream listener and starts listening immediately.
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

/// Bridges a [ChangeNotifier] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each notifier update and once immediately on
/// creation. Returning `false` from [mapper] cancels this instance.
class NotifierCancellable implements Cancellable {
  static int _eid = 0;

  /// Notifier to observe.
  final ChangeNotifier notifier;

  /// Internal event bridge used to serialize async [mapper] calls.
  final StreamController<int> _streamController = StreamController();

  /// Callback invoked on every notifier change.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedResult<Any> mapper;

  /// Creates a cancellable notifier listener and triggers initial mapping once.
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

/// Bridges a [ValueListenable] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each value update and once immediately with the
/// current value. Returning `false` from [mapper] cancels this instance.
class ListenableCancellable<T> implements Cancellable {
  /// Value listenable to observe.
  final ValueListenable<T> listenable;

  /// Internal event bridge used to serialize async [mapper] calls.
  final StreamController<T> _streamController = StreamController();

  /// Callback invoked on every value change.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedCallback<Any, T> mapper;

  /// Creates a cancellable value-listenable listener and maps current value once.
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
