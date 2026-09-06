import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Emits the first event immediately and suppresses subsequent events
/// for [duration].
class ThrottleStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// Throttle window.
  final Duration duration;

  /// Creates a throttle transformer with the provided [duration].
  ThrottleStreamTransformer(this.duration);

  @override
  /// Applies throttle behavior to [stream].
  Stream<T> bind(Stream<T> stream) {
    return Stream<T>.multi(
      (controller) {
        StreamSubscription<T>? subscription;
        Timer? timer;
        var ready = true;
        var isCancelled = false;
        var isPaused = false;
        Future<void>? sourceCancellation;
        Completer<void>? pendingCancellation;

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
            if (isCancelled || !ready) {
              return;
            }

            ready = false;
            timer?.cancel();
            timer = Timer(duration, () {
              timer = null;
              if (!isCancelled) {
                ready = true;
              }
            });
            controller.addSync(event);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!isCancelled) {
              controller.addErrorSync(error, stackTrace);
            }
          },
          onDone: () {
            timer?.cancel();
            timer = null;
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

extension ThrottleStreamTransformerExt<T> on Stream<T> {
  /// Returns a stream that emits at most one event per throttle window.
  ///
  /// Uses 300 milliseconds when [duration] is omitted.
  Stream<T> throttle([Duration? duration]) => transform(ThrottleStreamTransformer(duration ?? 300.milliseconds));
}
