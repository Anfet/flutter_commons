import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Public mixin WaitableEvent.
mixin WaitableEvent<T> {
  final Lazy<Completer<T>> completer = Lazy(() => Completer<T>());

  void complete([FutureOr<T>? result]) {
    if (!completer().isCompleted) {
      completer().complete(result);
    }
  }

  void fail(Object error, [StackTrace? stack]) {
    if (!completer().isCompleted) {
      completer().completeError(error, stack);
    }
  }
}

extension BlocWaitableEventExt<E extends BlocEvent, S> on Bloc<E, S> {
  /// Adds [event] and waits for its explicit [WaitableEvent.complete] or
  /// [WaitableEvent.fail] call.
  ///
  /// With no [timeout], this preserves the existing unbounded wait contract.
  /// A timeout or closing this Bloc completes the pending wait with
  /// [StaleWaitEventException]. Reusing an already completed event preserves
  /// its original completed future.
  Future<T> addAndWait<T>(E event, {Duration? timeout}) async {
    if (event is! WaitableEvent<T>) {
      throw IllegalArgumentException('Event $event must implement WaitableEvent<$T>');
    }
    final waitable = event as WaitableEvent<T>;

    // A WaitableEvent owns one completer. Preserve the legacy behavior for a
    // reused event without attaching a close monitor that can no longer help.
    if (waitable.completer().isCompleted) {
      add(event);
      return waitable.completer().future;
    }

    if (isClosed) {
      waitable.fail(StaleWaitEventException.blocClosed());
      return waitable.completer().future;
    }

    Timer? timeoutTimer;
    StreamSubscription<S>? closeMonitor;
    var isCleanedUp = false;

    void cleanUp() {
      if (isCleanedUp) return;
      isCleanedUp = true;
      timeoutTimer?.cancel();
      unawaited(closeMonitor?.cancel());
    }

    final future = waitable.completer().future;
    future.then<void>(
      (_) => cleanUp(),
      onError: (Object _, StackTrace __) => cleanUp(),
    );

    closeMonitor = stream.listen(
      null,
      onDone: () => waitable.fail(StaleWaitEventException.blocClosed()),
    );
    if (timeout != null) {
      timeoutTimer = Timer(
        timeout,
        () => waitable.fail(StaleWaitEventException.timeout(timeout)),
      );
    }

    try {
      add(event);
    } catch (_) {
      cleanUp();
      if (isClosed) {
        waitable.fail(StaleWaitEventException.blocClosed());
        return future;
      }
      rethrow;
    }
    return future;
  }
}
