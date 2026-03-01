import 'package:flutter/foundation.dart';

/// Stores a value together with a visibility flag.
///
/// Useful for UI state where the last value should be preserved even when it is
/// temporarily hidden.
class VisibleValue<T> {
  bool _isVisible;
  T _value;

  /// Whether current value should be shown.
  bool get isVisible => _isVisible;

  /// Stored value (kept even when hidden).
  T get value => _value;

  /// Creates state with [value] and optional initial visibility.
  VisibleValue(T value, [bool isVisible = true]) : _value = value, _isVisible = isVisible;

  /// Updates value and/or visibility and calls [onChanged] when state changed.
  void setValue(T? value, {bool? isVisible, VoidCallback? onChanged}) {
    final nextVisible = isVisible ?? (value != null);
    final changed = (value != null && _value != value) || nextVisible != _isVisible;

    _isVisible = nextVisible;
    if (value != null) {
      _value = value;
    }

    if (changed) onChanged?.call();
  }
}

