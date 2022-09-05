import 'package:flutter/foundation.dart';

extension ValueListenerExt<T> on ValueListenable<T> {
  ValueListenable<X> mapValue<X>(X Function(T it) block) => ValueNotifierMapper<T, X>(source: this, mapper: block);
}

class ValueNotifierMapper<T, X> extends ValueNotifier<X> {
  final ValueListenable<T> source;
  final X Function(T value) mapper;

  ValueNotifierMapper({required this.source, required this.mapper}) : super(mapper(source.value)) {
    source.addListener(onValueChanged);
  }

  void onValueChanged() {
    value = mapper(source.value);
  }

  @override
  void dispose() {
    source.removeListener(onValueChanged);
    super.dispose();
  }
}
