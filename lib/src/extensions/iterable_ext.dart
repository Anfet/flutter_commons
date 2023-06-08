import 'dart:math';

extension IterableExt<T> on Iterable<T> {
  bool isFirst(T item) => firstOrNull == item;

  bool isLast(T item) => lastOrNull == item;

  T firstOr(bool Function(T it) test, T defaultValue) {
    if (isEmpty) return defaultValue;

    try {
      return firstWhere((it) => test(it));
    } catch (ex) {
      return defaultValue;
    }
  }

  T? firstIf(bool Function(T it) test) {
    for (final item in this) {
      if (test(item)) return item;
    }

    return null;
  }

  Out? firstNotNullOr<Out>(Out? Function(T it) map, {Out? defaultValue}) {
    for (final item in this) {
      final result = map(item);
      if (item != null) return result;
    }
    return defaultValue;
  }

  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;

  T get randomElement => elementAt(Random().nextInt(length));

  bool any(bool Function(T it) test) {
    for (var element in this) {
      if (test(element)) return true;
    }

    return false;
  }

  bool all(bool Function(T it) test) {
    for (var element in this) {
      if (!test(element)) return false;
    }

    return true;
  }

  List<T> filter(bool Function(T it) test) {
    final List<T> out = List.empty(growable: true);
    for (final item in this) {
      if (test(item)) {
        out.add(item);
      }
    }
    return out;
  }

  /// cycles through items in list invoking [test] on each item until test returns true
  void forEachUntil(bool Function(T it) test) {
    for (final item in this) {
      if (test(item)) break;
    }
  }

  Future<Iterable<X>> asyncMap<X>(Future<X> Function(T it) mapper) async {
    final result = <X>[];
    for (final value in this) {
      X out = await mapper(value);
      result.add(out);
    }
    return result;
  }

  Iterable<X> filterIfIs<X>() {
    final result = <X>[];
    for (final value in this) {
      if (value is X) {
        result.add(value);
      }
    }
    return result;
  }

  Iterable<T> filterIfIsNot<X>() {
    final result = <T>[];
    for (final value in this) {
      if (value is! X) {
        result.add(value);
      }
    }
    return result;
  }

  Iterable<T> distinct() {
    Set<T> result = {};
    for (final value in this) {
      result.add(value);
    }
    return result;
  }

  num maxOf(num Function(T it) test, {num? orElse}) {
    num? x;
    for (final val in this) {
      x ??= test(val);
      x = max(x, test(val));
    }

    return x ?? orElse ?? 0;
  }

  num minOf(num Function(T it) test, {num? orElse}) {
    num? x;
    for (final val in this) {
      x ??= test(val);
      x = min(x, test(val));
    }

    return x ?? orElse ?? 0;
  }

  num sumOf(num Function(T it) test) {
    num x = 0;
    for (final val in this) {
      x += test(val);
    }
    return x;
  }
}
