import 'package:flutter/foundation.dart';

extension ValueListenerExt<T> on ValueListenable<T> {
  ///maps a value from source listenable to another via a mapper function.
  ///- [mapper] transformation function
  ///- [onDispose] is called when the resulting mapper is being disposed. Default implementation will remove the mapper listener,
  ///but you may wish to dispose the source listenable too
  ValueListenable<X> mapValue<X>(X Function(T it) mapper, {VoidCallback? onDispose}) => ValueNotifierMapper<T, X>(
        source: this,
        mapper: mapper,
      );
}

class ValueNotifierMapper<T, X> extends ValueNotifier<X> {
  final ValueListenable<T> source;
  final X Function(T value) mapper;
  final VoidCallback? onDispose;

  ValueNotifierMapper({required this.source, required this.mapper, this.onDispose}) : super(mapper(source.value)) {
    source.addListener(onValueChanged);
  }

  void onValueChanged() {
    value = mapper(source.value);
  }

  @override
  void dispose() {
    source.removeListener(onValueChanged);
    onDispose?.call();
    super.dispose();
  }
}
