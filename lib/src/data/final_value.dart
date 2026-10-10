/// A write-once container.
///
/// The value can be assigned only once via [value]. Any subsequent assignment
/// throws [StateError].
class FinalValue<T> {
  T? _value;
  bool _isSet = false;

  /// Whether the value has been assigned at least once.
  bool get isSet => _isSet;

  /// Returns assigned value; same as [take].
  T get requiredValue => take;

  /// Nullable accessor of current value.
  T? get value => tryTake;

  /// Assigns value once.
  set value(T? value) {
    if (_isSet) {
      throw StateError('value is already set');
    }
    _value = value;
    _isSet = true;
  }

  /// Returns assigned value.
  ///
  /// Throws [StateError] when the value is not set. An assigned `null` is
  /// returned as is when [T] is nullable; otherwise the cast to [T] throws.
  T get take {
    if (!_isSet) {
      throw StateError('value is not set');
    }
    return _value as T;
  }

  /// Returns assigned value or `null` when value has not been set.
  T? get tryTake => isSet ? _value : null;

  /// Compares the current state, which changes on the first assignment.
  ///
  /// Do not keep an unset instance in a [Set] or as a [Map] key: assigning the
  /// value changes its [hashCode].
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FinalValue && runtimeType == other.runtimeType && _isSet == other._isSet && _value == other._value;

  @override
  int get hashCode => Object.hash(runtimeType, _isSet, _value);

  /// Creates an instance with optional initial value.
  ///
  /// A `null` [value] leaves the instance unset; use [FinalValue.withValue] to
  /// store an explicit `null`.
  FinalValue([T? value]) : _value = value, _isSet = value != null;

  /// Creates an unset instance explicitly.
  FinalValue.unset() : _value = null, _isSet = false;

  /// Creates an instance that is set, including when [value] is null.
  FinalValue.withValue(T? value) : _value = value, _isSet = true;

  @override
  String toString() {
    return 'FinalValue{_value: $_value}';
  }
}
