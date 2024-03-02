import 'package:flutter/foundation.dart';

extension ChangeNotifierExt on ChangeNotifier {
  ValueListenable<T> map<T>(ValueGetter<T> getter) => _MappingValueNotifier(this, getter);
}

class _MappingValueNotifier<T> extends ValueNotifier<T> {
  final ChangeNotifier source;
  final ValueGetter<T> getter;

  _MappingValueNotifier(this.source, this.getter) : super(getter()) {
    source.addListener(_valueChanged);
  }

  void _valueChanged() {
    value = getter();
  }

  @override
  void dispose() {
    source.removeListener(_valueChanged);
    super.dispose();
  }
}
