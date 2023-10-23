class Maybe<T> {
  final T? value;

  const Maybe([this.value]);

  T? or(T? other) => value ?? other;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Maybe && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return 'Maybe{value: $value}';
  }
}

extension MaybeExtOnAny<T> on T {
  Maybe<T> get asMaybe => Maybe(this);
}
