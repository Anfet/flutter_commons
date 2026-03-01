import 'package:flutter_commons/flutter_commons.dart';

/// Default debounce window used by [debounce] when [duration] is omitted.
final Duration kDefaultDebounceDuration = 300.milliseconds;

/// Creates a `bloc` [EventTransformer] that emits only the latest event
/// after a quiet period.
///
/// Useful for search inputs or rapid UI interactions where only the latest
/// value should be processed.
EventTransformer<T> debounce<T>([Duration? duration]) {
  return (events, mapper) {
    final debounceDuration = duration ?? kDefaultDebounceDuration;
    return events.debounce(debounceDuration).asyncExpand(mapper);
  };
}
