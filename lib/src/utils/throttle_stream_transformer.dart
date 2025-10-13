import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';

class ThrottleStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  Timer? _timer;
  bool _ready = true;
  late StreamController<T> _controller;

  ThrottleStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    _controller = StreamController<T>();

    stream.listen((event) {
      if (_ready) {
        _controller.add(event);
        _ready = false;
        _timer = Timer(duration, () => _ready = true);
      }
    }, onError: _controller.addError, onDone: _controller.close);

    return _controller.stream;
  }
}

extension ThrottleStreamTransformerExt<T> on Stream<T> {
  Stream<T> throttle([Duration? duration]) => this.transform(ThrottleStreamTransformer(duration ?? 300.milliseconds));
}
