import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

final Duration kDefaultDebounceDuration = 300.milliseconds;

EventTransformer<T> debounce<T>([Duration? duration]) {
  return (events, mapper) {
    return events.transform(
      StreamTransformer<T, T>.fromBind(
        (stream) {
          Timer? timer;
          final controller = StreamController<T>();

          stream.listen(
            (event) {
              timer?.cancel();
              timer = Timer(duration ?? kDefaultDebounceDuration, () => controller.add(event));
            },
            onError: controller.addError,
            onDone: () {
              timer?.cancel();
              controller.close();
            },
          );

          return controller.stream;
        },
      ),
    ).asyncExpand(mapper);
  };
}
