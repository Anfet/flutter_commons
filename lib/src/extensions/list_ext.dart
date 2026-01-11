import 'dart:math';

import 'iterable_ext.dart';

typedef SortFunc<T> = int Function(T a, T b);

extension ListExt<T> on List<T> {
  List<T> clone() => List.of(this);

  T nextOrLast(T it) => isLast(it) ? it : (elementAt(indexOf(it) + 1));

  T nextOrFirst(T it) => isLast(it) ? first : (elementAt(indexOf(it) + 1));

  T priorOrFirst(T it) => isFirst(it) ? it : (elementAt(indexOf(it) - 1));

  T priorOrLast(T it) => isFirst(it) ? last : (elementAt(indexOf(it) - 1));

  List<T> toggle(T it) {
    final result = List.of(this);
    result.contains(it) ? result.remove(it) : result.add(it);
    return result;
  }

  List<X> map<X>(X Function(T it) mapper) => this.map((it) => mapper(it)).toList();

  List<T> extract(int amount, {int from = 0}) {
    assert(length > from, 'Original list has $length elements, cannot extract $amount from $from');
    List<T> result = <T>[];
    while (result.length < amount && !isEmpty) {
      result.add(removeAt(from));
    }

    return result;
  }

  List<T> replaceIf(bool Function(T it) test, T newValue, [bool replaceAll = true]) {
    final result = clone();
    for (var i = 0; i < length; i++) {
      final item = result[i];
      if (test(item)) {
        result[i] = newValue;
        if (!replaceAll) {
          break;
        }
      }
    }

    return result;
  }

  List<T> removeIf(bool Function(T it) test) => filter((it) => !test(it));

  List<T> replaceWith(bool Function(T it) test, T Function(T old) replacer, {bool replaceAll = true}) {
    List<T> result = clone();
    for (var i = 0; i < result.length; i++) {
      var item = result[i];
      if (test(item)) {
        result[i] = replacer(item);
        if (!replaceAll) {
          break;
        }
      }
    }
    return result;
  }

  List<T> addOrReplace(T value, bool Function(T it) test) {
    List<T> result = clone();

    for (var i = 0; i < result.length; i++) {
      final item = result[i];
      if (test(item)) {
        result[i] = value;
        return result;
      }
    }

    result.add(value);
    return result;
  }

  List<T> multiSortBy(List<SortFunc<T>> sort) {
    List<T> result = clone();

    result.sort((a, b) {
      int result = 0;
      for (final func in sort) {
        result = func(a, b);
        if (result != 0) {
          break;
        }
      }
      return result;
    });

    return result;
  }

  List<T> tryAdd(T? value) {
    List<T> result = clone();

    if (value != null) {
      result.add(value);
    }

    return result;
  }

  List<T> sortedBy(SortFunc<T> sf) {
    var result = this.clone();
    result.sort(sf);
    return result;
  }

  List<T> takeRandom([int count = 1]) {
    var result = <T>[];
    for (int i = 0; i < count; i++) {
      result.add(randomElement);
    }
    return result;
  }

  List<List<T>> splitBy(int amount) {
    var copy = this.clone();
    List<List<T>> result = [];

    while (copy.isNotEmpty) {
      result.add(copy.take(amount).toList(growable: false));
      copy.removeRange(0, copy.length >= amount ? amount : copy.length);
    }

    return result;
  }

  List<X> mapIndexed<X>(X Function(int index, T value) mapper) {
    var result = <X>[];
    for (int i = 0; i < length; i++) {
      result.add(mapper(i, this[i]));
    }
    return result;
  }

  List<T> replaceEach(T Function(T it) mapper) => map(mapper).toList();

  List<T> replaceAt(int index, T Function(T old) mapper) {
    var result = clone();
    result[index] = mapper(result[index]);
    return result;
  }

  List<T> swap(int oldIndex, int newIndex) {
    var result = clone();
    result.swapThis(oldIndex, newIndex);
    return result;
  }

  void swapThis(int oldIndex, int newIndex) {
    var a = this[oldIndex];
    var b = this[newIndex];
    this[oldIndex] = b;
    this[newIndex] = a;
  }

  List<T> takeCount(int count, {bool remove = false}) {
    if (count == 0) {
      return [];
    }

    var canTake = min(this.length, count);
    var result = this.sublist(0, canTake);
    if (remove) {
      this.removeRange(0, canTake);
    }
    return result;
  }

  List<T> takeLastCount(int count, {bool remove = false}) {
    if (count == 0) {
      return [];
    }

    var canTake = min(this.length, count);
    var result = this.sublist(length - canTake, length);
    if (remove) {
      this.removeRange(length - canTake, length);
    }
    return result;
  }
}
