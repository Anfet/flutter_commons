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
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? timer;
    T? pendingEvent;
    var hasPendingEvent = false;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = stream.listen(
          (event) {
            pendingEvent = event;
            hasPendingEvent = true;
            timer?.cancel();
            timer = Timer(duration, () {
              if (!hasPendingEvent) {
                return;
              }
              controller.add(pendingEvent as T);
              hasPendingEvent = false;
              pendingEvent = null;
            });
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            if (hasPendingEvent) {
              controller.add(pendingEvent as T);
              hasPendingEvent = false;
              pendingEvent = null;
            }
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

extension DebounceStreamTransformerExt<T> on Stream<T> {
  /// Returns a stream that emits only the latest value after a quiet period.
  ///
  /// Uses 300 milliseconds when [duration] is omitted.
  Stream<T> debounce([Duration? duration]) => transform(DebounceStreamTransformer(duration ?? 300.milliseconds));
}
