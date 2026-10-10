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
  ///
  /// A `null` [value] means "keep the stored value"; without an explicit
  /// [isVisible] it also hides it. To store `null` itself when [T] is nullable,
  /// use [assign].
  void setValue(T? value, {bool? isVisible, VoidCallback? onChanged}) {
    final nextVisible = isVisible ?? (value != null);
    final changed = (value != null && _value != value) || nextVisible != _isVisible;

    _isVisible = nextVisible;
    if (value != null) {
      _value = value;
    }

    if (changed) onChanged?.call();
  }

  /// Stores [value] as is, including `null` when [T] is nullable, sets
  /// visibility to [isVisible] and calls [onChanged] when state changed.
  void assign(T value, {bool isVisible = true, VoidCallback? onChanged}) {
    final changed = _value != value || _isVisible != isVisible;

    _value = value;
    _isVisible = isVisible;

    if (changed) onChanged?.call();
  }
}
