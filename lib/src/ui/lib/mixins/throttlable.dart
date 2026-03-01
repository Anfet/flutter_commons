import 'package:flutter_commons/flutter_commons.dart';

/// Default throttle window used by [throttle] when [duration] is omitted.
final Duration kDefaultThrottleDuration = 300.milliseconds;

/// Creates a `bloc` [EventTransformer] that lets the first event pass
/// immediately and suppresses subsequent events for a fixed time window.
EventTransformer<T> throttle<T>([Duration? duration]) {
  return (events, mapper) {
    final throttleDuration = duration ?? kDefaultThrottleDuration;
    return events.throttle(throttleDuration).asyncExpand(mapper);
  };
}
