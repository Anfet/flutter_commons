extension SiberianFutureIterableExt<T> on Future<Iterable<T>> {
  Future<List<T>> toList() => then((it) => it.toList());
}
