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
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? timer;
    var ready = true;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = stream.listen(
          (event) {
            if (!ready) {
              return;
            }

            controller.add(event);
            ready = false;
            timer?.cancel();
            timer = Timer(duration, () => ready = true);
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

extension ThrottleStreamTransformerExt<T> on Stream<T> {
  /// Returns a stream that emits at most one event per throttle window.
  ///
  /// Uses 300 milliseconds when [duration] is omitted.
  Stream<T> throttle([Duration? duration]) => transform(ThrottleStreamTransformer(duration ?? 300.milliseconds));
}
