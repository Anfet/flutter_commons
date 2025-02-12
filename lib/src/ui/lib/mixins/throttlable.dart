import 'package:flutter_commons/flutter_commons.dart';
import 'package:stream_transform/stream_transform.dart';

final Duration kDefaultThrottleDuration = 300.milliseconds;

EventTransformer<T> throttle<T>([Duration? duration]) {
  return (events, mapper) => events.throttle(duration ?? kDefaultThrottleDuration).switchMap(mapper);
}
