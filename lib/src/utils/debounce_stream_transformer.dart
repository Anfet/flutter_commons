import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  DateTime _lastMessage = DateTime(0);
  StreamController<T>? _controller;

  DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    _controller = StreamController<T>();
    stream.listen(_onEvent, onError: _controller?.addError, onDone: _controller?.close);
    return _controller!.stream;
  }

  void _onEvent(T event) {
    if (_lastMessage.difference(DateTime.now()).abs().inMilliseconds >= duration.inMilliseconds) {
      _controller?.add(event);
      _lastMessage = DateTime.now();
    }
  }
}

extension DebounceStreamTransformerExt<T> on Stream<T> {
  Stream<T> debounce([Duration? duration]) => this.transform(DebounceStreamTransformer(duration ?? 300.milliseconds));
}
