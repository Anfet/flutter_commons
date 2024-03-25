import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:siberian_core/siberian_core.dart';

class ListenableProperty<T> with ChangeNotifier implements Property<T> {
  final Property<T> child;

  ListenableProperty(this.child);

  @override
  T get cachedValue => child.cachedValue;

  @override
  FutureOr<void> delete() async {
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
