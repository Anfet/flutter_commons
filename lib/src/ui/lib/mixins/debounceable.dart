import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

/// Default debounce window used by [debounce] when [duration] is omitted.
final Duration kDefaultDebounceDuration = 300.milliseconds;

/// Creates a `bloc` [EventTransformer] that emits only the latest event
/// after a quiet period.
///
/// Useful for search inputs or rapid UI interactions where only the latest
/// value should be processed. Handlers run one after another: a slow handler
/// delays the next debounced event. Use [debounceRestartable] when a newer
/// event should cancel the handler that is still running.
EventTransformer<T> debounce<T>([Duration? duration]) {
  return (events, mapper) {
    final debounceDuration = duration ?? kDefaultDebounceDuration;
    return events.debounce(debounceDuration).asyncExpand(mapper);
  };
}

/// Like [debounce], but a newer debounced event cancels the handler of the
/// previous one.
///
/// After cancellation the previous handler's `emit` calls are ignored, so a
/// slow response for an outdated search query never overwrites the newer one.
EventTransformer<T> debounceRestartable<T>([Duration? duration]) {
  return (events, mapper) => events.debounce(duration ?? kDefaultDebounceDuration).switchMap(mapper);
}

extension _SwitchMapExt<T> on Stream<T> {
  /// Maps every event to a stream, cancelling the stream of the previous event.
  Stream<R> switchMap<R>(Stream<R> Function(T event) mapper) {
    late final StreamController<R> controller;
    StreamSubscription<T>? outer;
    StreamSubscription<R>? inner;
    var isOuterDone = false;

    void closeIfDone() {
      if (isOuterDone && inner == null) {
        controller.close().ignore();
      }
    }

    controller = StreamController<R>(
      onListen: () {
        outer = listen(
          (event) {
            inner?.cancel().ignore();
            final current = mapper(event).listen(controller.add, onError: controller.addError);
            inner = current;
            current.onDone(() {
              if (identical(inner, current)) {
                inner = null;
                closeIfDone();
              }
            });
          },
          onError: controller.addError,
          onDone: () {
            isOuterDone = true;
            closeIfDone();
          },
        );
      },
      onPause: () {
        outer?.pause();
        inner?.pause();
      },
      onResume: () {
        outer?.resume();
        inner?.resume();
      },
      onCancel: () => Future.wait<void>([?outer?.cancel(), ?inner?.cancel()]),
    );
    return controller.stream;
  }
}
