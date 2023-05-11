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

  List<T> multiSortBy(List<SortFunc<T>> sort, {bool asc = true}) {
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

    if (!asc) {
      return result.reversed.toList();
    }

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

  List<T> insertInBetween(T Function(int index) generator) {
    final result = <T>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(generator(i));
      }
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
}
