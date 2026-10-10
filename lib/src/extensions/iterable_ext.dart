import 'dart:async';
import 'dart:math';

import 'package:flutter_commons/flutter_commons.dart';

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
      if (result != null) {
        return result;
      }
    }
    return defaultValue;
  }

  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;

  T get randomElement => isEmpty ? throw StateError('No element') : elementAt(random.nextInt(length));

  T? get randomOrNull => isEmpty ? null : elementAt(random.nextInt(length));

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
    final result = <T>[];
    final seen = <dynamic>{};

    for (final value in this) {
      final key = test != null ? test(value) : value;
      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      result.add(value);
    }
    return result;
  }

  /// Largest [test] result (or element, when [test] is omitted and elements are numbers).
  /// Returns [orElse], or 0, for an empty collection.
  num maxOf([num Function(T it)? test, num? orElse]) {
    num? x;
    for (final val in this) {
      final t = _numberOf(val, test);
      x = x == null ? t : max(x, t);
    }

    return x ?? orElse ?? 0;
  }

  /// Smallest [test] result (or element, when [test] is omitted and elements are numbers).
  /// Returns [orElse], or 0, for an empty collection.
  num minOf([num Function(T it)? test, num? orElse]) {
    num? x;
    for (final val in this) {
      final t = _numberOf(val, test);
      x = x == null ? t : min(x, t);
    }

    return x ?? orElse ?? 0;
  }

  /// Sum of [test] results (or elements, when [test] is omitted and elements are numbers).
  num sumOf([num Function(T it)? test]) {
    num x = 0;
    for (final val in this) {
      x += _numberOf(val, test);
    }
    return x;
  }

  static num _numberOf<T>(T value, num Function(T it)? test) {
    if (test != null) {
      return test(value);
    }
    if (value is num) {
      return value;
    }
    throw ArgumentError('A test is required for non-numeric elements');
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

  List<X> mapList<X>(X Function(T value) mapper) => map(mapper).toList();

  Future<List<X>> mapListAsync<X>(FutureOr<X> Function(T value) mapper) => asyncMap<X>((it) async => mapper(it)).then((i) => i.toList());

  Iterable<Maybe<T>> toMaybe() => map((it) => Maybe(it));
}
