import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Emits only the last event after a quiet period of [duration].
class DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// Debounce window.
  final Duration duration;

  /// Creates a debounce transformer with the provided [duration].
  DebounceStreamTransformer(this.duration);

  @override
  /// Applies debounce behavior to [stream].
  Stream<T> bind(Stream<T> stream) {
    return Stream<T>.multi(
      (controller) {
        StreamSubscription<T>? subscription;
        Timer? timer;
        T? pendingEvent;
        var hasPendingEvent = false;
        var isCancelled = false;
        var isPaused = false;
        Future<void>? sourceCancellation;
        Completer<void>? pendingCancellation;

        void emitPendingEvent() {
          if (isCancelled || !hasPendingEvent) {
            return;
          }

          final event = pendingEvent as T;
          hasPendingEvent = false;
          pendingEvent = null;
          controller.addSync(event);
        }

        Future<void> cancelSource() {
          isCancelled = true;
          timer?.cancel();
          timer = null;

          final activeSubscription = subscription;
          if (activeSubscription != null) {
            return sourceCancellation ??= activeSubscription.cancel();
          }

          return (pendingCancellation ??= Completer<void>()).future;
        }

        controller
          ..onCancel = cancelSource
          ..onPause = () {
            isPaused = true;
            subscription?.pause();
          }
          ..onResume = () {
            isPaused = false;
            subscription?.resume();
          };

        subscription = stream.listen(
          (event) {
            if (isCancelled) {
              return;
            }

            pendingEvent = event;
            hasPendingEvent = true;
            timer?.cancel();
            timer = Timer(duration, () {
              timer = null;
              emitPendingEvent();
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!isCancelled) {
              controller.addErrorSync(error, stackTrace);
            }
          },
          onDone: () {
            timer?.cancel();
            timer = null;
            emitPendingEvent();
            if (!isCancelled) {
              controller.closeSync();
            }
          },
        );

        if (isPaused) {
          subscription.pause();
        }
        if (isCancelled) {
          sourceCancellation ??= subscription.cancel();
          final cancellation = pendingCancellation;
          final activeCancellation = sourceCancellation;
          if (cancellation != null && activeCancellation != null) {
            activeCancellation.then(
              (_) => cancellation.complete(),
              onError: cancellation.completeError,
            );
          }
        }
      },
      isBroadcast: stream.isBroadcast,
    );
  }
}

extension DebounceStreamTransformerExt<T> on Stream<T> {
  /// Returns a stream that emits only the latest value after a quiet period.
  ///
  /// Uses 300 milliseconds when [duration] is omitted.
  Stream<T> debounce([Duration? duration]) => transform(DebounceStreamTransformer(duration ?? 300.milliseconds));
}
