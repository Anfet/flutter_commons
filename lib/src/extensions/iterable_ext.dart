import 'dart:async';
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

  Future<Iterable<X>> asyncMap<X>(FutureOr<X> Function(T it) mapper) async {
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

  Iterable<T> distinct([dynamic Function(T it)? test]) {
    Set<T> result = {};
    Set tests = {};
    for (final value in this) {
      var testValue = test?.call(value);
      if (testValue != null && tests.contains(testValue)) {
        continue;
      }

      tests.add(testValue);
      result.add(value);
    }
    return result;
  }

  num maxOf([num Function(T it)? test, num? orElse]) {
    // assert(T is num || T is double || T is int || test != null, 'T must be num|int|double or test is required');
    num? x;
    for (final val in this) {
      num t;
      if (val is num || val is int || val is double) {
        t = val as num;
      } else {
        t = test!.call(val);
      }

      x ??= val as num;
      x = max(x, t);
    }

    return x ?? orElse ?? 0;
  }

  num minOf([num Function(T it)? test, num? orElse]) {
    // assert(T is num || T is double || T is int || test != null, 'T must be num|int|double or test is required');
    num? x;
    for (final val in this) {
      num t;
      if (val is num || val is int || val is double) {
        t = val as num;
      } else {
        t = test!.call(val);
      }

      x ??= val as num;
      x = min(x, t);
    }

    return x ?? orElse ?? 0;
  }

  num sumOf([num Function(T it)? test]) {
    num x = 0;
    for (final val in this) {
      // assert(val is num || val is double || val is int || test != null, 'T must be num|int|double or test is required');
      if (val is num || val is int || val is double) {
        x += val as num;
      } else {
        x += test!.call(val);
      }
    }
    return x;
  }

  int count([bool Function(T it)? test]) {
    if (test == null) {
      return length;
    }

    var count = 0;
    for (final val in this) {
      if (test(val)) {
        count++;
      }
    }
    return count;
  }

  List<X> mapList<X>(X mapper(T value)) => map(mapper).toList();

  Future<List<X>> mapListAsync<X>(FutureOr<X> mapper(T value)) => asyncMap<X>((it) async => mapper(it)).then((i) => i.toList());
}
