class FinalValue<T> {
  T? _value;

  bool get isSet => _value != null;

  T get requiredValue => _value!;

  T? get value => tryTake;

  set value(T? value) {
    assert(_value == null, "value is already set!");
    _value = value;
  }

  T get take {
    assert(isSet, "value is not set");
    return _value!;
  }

  T? get tryTake => isSet ? take : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FinalValue && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  FinalValue([T? value]) : _value = value;

  @override
  String toString() {
    return 'FinalValue{_value: $_value}';
  }
}
