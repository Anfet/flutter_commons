class Nullable<T> {
  final T? value;

  T get requiredValue => value!;

  bool get hasValue => value != null;

  Nullable(this.value);

  Nullable copyWith({T? value}) => Nullable(value);
}
