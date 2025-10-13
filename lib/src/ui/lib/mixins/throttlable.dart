import 'package:flutter_commons/flutter_commons.dart';

final Duration kDefaultThrottleDuration = 300.milliseconds;

EventTransformer<T> throttle<T>([Duration? duration]) {
  return (events, mapper) => events.throttle(duration ?? kDefaultThrottleDuration) ;
}
