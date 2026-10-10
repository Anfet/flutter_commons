import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Lets a Bloc event return a result of type [T] to [BlocWaitableEventExt.addAndWait].
///
/// The handler finishes the wait with [complete] or [fail]; later calls are ignored.
mixin WaitableEvent<T> {
  final Lazy<Completer<T>> completer = Lazy(() => Completer<T>());

  /// Completes the wait with [result].
  ///
  /// [result] may be omitted only when [T] is nullable. Omitting it for a
  /// non-nullable [T] fails the wait with an [ArgumentError] instead of
  /// throwing inside the handler and leaving the caller waiting.
  void complete([FutureOr<T>? result]) {
    if (completer().isCompleted) {
      return;
    }
    if (result == null && null is! T) {
      completer().completeError(ArgumentError('$runtimeType.complete() requires a result of type $T'), StackTrace.current);
      return;
    }
    completer().complete(result);
  }

  void fail(Object error, [StackTrace? stack]) {
    if (!completer().isCompleted) {
      completer().completeError(error, stack);
    }
  }

  void _closeIfPending(Object? error, StackTrace? stackTrace) {
    if (completer().isCompleted) {
      return;
    }
    if (error != null) {
      fail(error, stackTrace);
    } else if (null is T) {
      complete();
    } else {
      fail(StateError('$runtimeType handler finished without complete()'), StackTrace.current);
    }
  }
}

/// Fails [event] with [StaleWaitEventException.dropped] if it is a pending [WaitableEvent].
///
/// The `debounce`, `debounceRestartable` and `throttle` event transformers of
/// this package call it for every event they drop. A custom transformer that
/// drops events should call it as well, otherwise `addAndWait` for a dropped
/// event waits until its timeout or the Bloc closes.
void failDroppedWaitableEvent(Object? event) {
  if (event is WaitableEvent) {
    event.fail(StaleWaitEventException.dropped());
  }
}

/// Closes every [WaitableEvent] whose handler finished without completing it.
///
/// When the handler of a waitable event returns or throws, a pending wait is
/// finished from [onDone]:
/// - the handler threw: the wait fails with that error and stack trace;
/// - the event's result type is `void` or nullable: the wait completes with `null`;
/// - otherwise: the wait fails with a [StateError] naming the event.
///
/// Explicit [WaitableEvent.complete] and [WaitableEvent.fail] calls made by the
/// handler always win.
///
/// Not supported: completing an event after its handler returned (from another
/// event, a callback or an unawaited future) — the wait is already closed by
/// then. Events dropped by a transformer never reach a handler or [onDone];
/// the transformers of this package fail them through
/// [failDroppedWaitableEvent], third-party ones (for example droppable from
/// `bloc_concurrency`) leave them waiting until the timeout or Bloc close.
mixin AutoCloseWaitableEvents<E, S> on Bloc<E, S> {
  @override
  void onDone(E event, [Object? error, StackTrace? stackTrace]) {
    super.onDone(event, error, stackTrace);
    if (event is WaitableEvent) {
      event._closeIfPending(error, stackTrace);
    }
  }
}

extension BlocWaitableEventExt<E extends BlocEvent, S> on Bloc<E, S> {
  /// Adds [event] and waits for its explicit [WaitableEvent.complete] or
  /// [WaitableEvent.fail] call.
  ///
  /// The parameter type makes an event without [WaitableEvent] a compile-time
  /// error, and [T] is inferred from it: `await bloc.addAndWait(LoadUser())`.
  /// An event that is not an [E] of this Bloc fails with
  /// [IllegalArgumentException].
  ///
  /// With no [timeout], this preserves the existing unbounded wait contract.
  /// A timeout or closing this Bloc completes the pending wait with
  /// [StaleWaitEventException]; the event itself is still handled if it was
  /// already added. Reusing an already completed event preserves its original
  /// completed future.
  Future<T> addAndWait<T>(WaitableEvent<T> event, {Duration? timeout}) async {
    if (event is! E) {
      throw IllegalArgumentException('Event $event is not an event of $runtimeType');
    }
    // No promotion: E is not a subtype of WaitableEvent<T>, so the checked event is cast once.
    final blocEvent = event as E;

    // A WaitableEvent owns one completer. Preserve the legacy behavior for a
    // reused event without attaching a close monitor that can no longer help.
    if (event.completer().isCompleted) {
      add(blocEvent);
      return event.completer().future;
    }

    if (isClosed) {
      event.fail(StaleWaitEventException.blocClosed());
      return event.completer().future;
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

    final future = event.completer().future;
    future.then<void>(
      (_) => cleanUp(),
      onError: (Object _, StackTrace __) => cleanUp(),
    );

    closeMonitor = stream.listen(
      null,
      onDone: () => event.fail(StaleWaitEventException.blocClosed()),
    );
    if (timeout != null) {
      timeoutTimer = Timer(
        timeout,
        () => event.fail(StaleWaitEventException.timeout(timeout)),
      );
    }

    try {
      add(blocEvent);
    } catch (_) {
      cleanUp();
      if (isClosed) {
        event.fail(StaleWaitEventException.blocClosed());
        return future;
      }
      rethrow;
    }
    return future;
  }
}
