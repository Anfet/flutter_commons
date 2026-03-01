/// A write-once container.
///
/// The value can be assigned only once via [value]. Any subsequent assignment
/// throws [StateError] (and also triggers an assertion in debug mode).
class FinalValue<T> {
  T? _value;
  bool _isSet = false;

  /// Whether the value has been assigned at least once.
  bool get isSet => _isSet;

  /// Returns assigned value, expecting it to be non-null.
  T get requiredValue => _value!;

  /// Nullable accessor of current value.
  T? get value => tryTake;

  /// Assigns value once.
  set value(T? value) {
    assert(!_isSet, "value is already set!");
    if (_isSet) {
      throw StateError('value is already set');
    }
    _value = value;
    _isSet = true;
  }

  /// Returns assigned value and expects it to be set and non-null.
  T get take {
    assert(isSet, "value is not set");
    return _value!;
  }

  /// Returns assigned value or `null` when value has not been set.
  T? get tryTake => isSet ? _value : null;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FinalValue && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Creates an instance with optional initial value.
  FinalValue([T? value]) : _value = value, _isSet = value != null;

  @override
  String toString() {
    return 'FinalValue{_value: $_value}';
  }
}
