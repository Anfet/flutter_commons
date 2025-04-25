extension SiberianFutureIterableExt<T> on Future<Iterable<T>> {
  Future<List<T>> toList() => then((it) => it.toList());

  Future<Iterable<X>> map<X>(X Function(T item) mapper) => then((iterable) => iterable.map(mapper));
}

extension LibFutureMapExt<K, V> on Future<Map<K, V>> {
  Future<Map<K1, V1>> map<K1, V1>(MapEntry<K1, V1> Function(K key, V value) convert) => then((value) => value.map(convert));

  Future<Iterable<K>> get keys => then((value) => value.keys);

  Future<Iterable<V>> get values => then((value) => value.values);
}
