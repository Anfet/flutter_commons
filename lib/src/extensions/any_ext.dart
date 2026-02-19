extension AnyExt<T> on T {
  X let<X>(X Function(T it) block) => block.call(this);

  T use(void Function(T it) block) {
    block.call(this);
    return this;
  }

  T? takeIf(bool Function(T it) test) => test.call(this) ? this : null;

  T? takeUnless(bool Function(T it) test) => test.call(this) ? null : this;

  bool containsIn(Iterable<T> list) => list.contains(this);

  bool isEither(Iterable<T> list) => list.contains(this);

  X? takeIfIs<X>() => this is X ? this as X : null;
}
