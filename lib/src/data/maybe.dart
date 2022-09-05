class Maybe<T> {
  final T? value;

  Maybe(this.value);

  T? or(T? other) => value ?? other;
}
