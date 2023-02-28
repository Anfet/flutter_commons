extension AnyExt<T> on T {
  X let<X>(X Function(T it) block) => block.call(this);

  X to<X>(X value) => value;

  T use(void Function(T it) block) {
    block.call(this);
    return this;
  }

  T? takeIf(bool Function(T it) test) => test.call(this) ? this : null;

  T? takeUnless(bool Function(T it) test) => test.call(this) ? null : this;

  bool containsIn(List<T> list) => list.contains(this);
}
