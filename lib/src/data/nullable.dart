class Nullable<T> {
  final T? value;

  T get requiredValue => value!;

  bool get hasValue => value != null;

  Nullable(this.value);

  Nullable copyWith({T? value}) => Nullable(value);

  @override
  bool operator ==(Object other) => identical(this, other) || other is Nullable && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return 'Nullable{value: $value}';
  }
}
