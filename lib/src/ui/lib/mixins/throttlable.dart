import 'package:flutter_commons/flutter_commons.dart';

final Duration kDefaultThrottleDuration = 300.milliseconds;

EventTransformer<T> throttle<T>([Duration? duration]) {
  return (events, mapper) {
    DateTime lastEmission = DateTime.fromMillisecondsSinceEpoch(0);

    return events.where(
      (event) {
        final now = DateTime.now();
        final diff = now.difference(lastEmission).inMilliseconds;
        if (diff >= (duration ?? kDefaultThrottleDuration).inMilliseconds) {
          lastEmission = now;
          return true;
        }
        return false;
      },
    ).asyncExpand(mapper);
  };
}
