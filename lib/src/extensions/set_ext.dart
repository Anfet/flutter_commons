extension SetExt<T> on Set<T> {
  Set<T> minus(T element) => toSet()..remove(element);
}
