/// Lightweight optional wrapper around a nullable value.
///
/// Useful when an explicit "maybe present" type is preferred over using `T?`
/// directly in APIs.
class Maybe<T> {
  /// Wrapped nullable value.
  final T? value;

  /// Creates optional value wrapper.
  const Maybe([this.value]);

  /// Creates empty optional wrapper.
  const Maybe.nothing() : value = null;

  /// Returns wrapped value or [other] fallback.
  T? or(T? other) => value ?? other;

  /// Non-null value accessor.
  T get requireValue => value!;

  /// Shorthand for [requireValue].
  T get rv => value!;

  /// Shorthand for [value].
  T? get v => value;

  /// Whether value is present.
  bool get hasValue => value != null;

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
  /// Wraps this value into [Maybe].
  Maybe<T> get asMaybe => Maybe(this);
}
