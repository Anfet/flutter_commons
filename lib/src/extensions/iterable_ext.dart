import 'dart:math';

extension IterableExt<T> on Iterable<T> {
  bool isFirst(T item) => firstOrNull == item;

  bool isLast(T item) => lastOrNull == item;

  T firstOr(bool Function(T it) test, T defaultValue) {
    var value = firstIf(test);
    return value ?? defaultValue;
  }

  T? firstIf(bool Function(T it) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
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

  bool anyOf(bool Function(T it) test) {
    for (var element in this) {
      if (test(element)) return true;
    }

    return false;
  }

  bool allOf(bool Function(T it) test) {
    for (var element in this) {
      if (!test(element)) return false;
    }

    return true;
  }

  List<T> filter(bool Function(T it) test) {
    final List<T> out = <T>[];
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
      if (test(item)) {
        break;
      }
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

  Iterable<T> distinct([bool Function(T it)? test]) {
    Set<T> result = {};
    for (final value in this) {
      var testResult = test?.call(value) ?? true;
      if (testResult) {
        result.add(value);
      }
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

  int count(bool Function(T it) test) {
    var count = 0;
    for (final val in this) {
      if (test(val)) {
        count++;
      }
    }
    return count;
  }
}
