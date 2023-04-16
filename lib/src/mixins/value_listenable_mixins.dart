import 'package:flutter/foundation.dart';
import 'package:siberian_core/src/functions.dart';

mixin ValueListenableMixin {
  final Map<ValueListenable, List<VoidCallback>> _valueListenableSubscriptions = {};

  void onValueChanged<T extends Object>(ValueListenable<T> valueListenable, TypedCallback<T> onChange) {
    listener() => onChange(valueListenable.value);
    _valueListenableSubscriptions.putIfAbsent(valueListenable, () => []).add(listener);
    valueListenable.addListener(listener);
  }

  void removeListeners() {
    for (var notifier in _valueListenableSubscriptions.keys) {
      for (var listener in _valueListenableSubscriptions[notifier]!) {
        notifier.removeListener(listener);
      }
    }
  }
}
