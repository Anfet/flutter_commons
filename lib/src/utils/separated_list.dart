/// Utility for building interleaved item/separator lists.
class SeparatedList {
  SeparatedList._();

  /// Maps [list] items with [builder] and inserts separators from [separatorBuilder]
  /// between neighboring items when provided.
  static List<T> builder<X, T>(
    List<X> list, {
    required T Function(int index, X item, List<X> list) builder,
    T? Function(int index, X item, List<X> list)? separatorBuilder,
  }) {
    final result = <T>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final mapped = builder(i, item, list);
      result.add(mapped);

      if (i < list.length - 1) {
        final separator = separatorBuilder?.call(i, item, list);
        if (separator != null) {
          result.add(separator);
        }
      }
    }

    return result;
  }
}
