import 'package:flutter_commons/flutter_commons.dart';
import 'package:stream_transform/stream_transform.dart';

final Duration kDefaultDebounceDuration = 300.milliseconds;

EventTransformer<T> debounce<T>([Duration? duration]) {
  return (events, mapper) => events.debounce(duration ?? kDefaultDebounceDuration).switchMap(mapper);
}
