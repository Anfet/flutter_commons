import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

class ListenableProperty<T> with ChangeNotifier implements StorableProperty<T> {
  final StorableProperty<T> child;

  ListenableProperty(this.child);

  @override
  T get cachedValue => child.cachedValue;

  @override
  Future<void> delete() async {
    await child.delete();
    notifyListeners();
  }

  @override
  FutureOr<T> getValue() => child.getValue();

  @override
  Future<void> setValue(T val) async {
    await child.setValue(val);
    notifyListeners();
  }
}
