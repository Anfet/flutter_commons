import 'package:flutter/foundation.dart';

class VisibleValue<T> {
  bool _isVisible;
  T _value;

  bool get isVisible => _isVisible;

  T get value => _value;

  VisibleValue(T value, [bool isVisible = true]) : _value = value, _isVisible = isVisible;

  void setValue(T? value, {bool? isVisible, VoidCallback? onChanged}) {
    var changed = _value != value || (isVisible ?? _isVisible) != _isVisible;

    _isVisible = isVisible ?? (value != null);
    if (value != null) {
      _value = value;
    }

    if (changed) onChanged?.call();
  }
}

