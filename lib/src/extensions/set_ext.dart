extension SetExt<T> on Set<T> {
  Set<T> operator -(Iterable<T> elements) => Set.of(this)..removeAll(elements);

  Set<T> operator +(Iterable<T> elements) => Set.of(this)..addAll(elements);

  Set<T> toggle(T it) => contains(it) ? this + [it] : this - [it];
}
