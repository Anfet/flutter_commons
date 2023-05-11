import 'package:flutter/foundation.dart';
import 'package:siberian_core/src/functions.dart';

mixin ValueListenableMixin {
  final Map<ValueListenable, List<VoidCallback>> _valueListenableSubscriptions = {};

  void listenToValueChanges<T extends Object>(ValueListenable<T> valueListenable, TypedCallback<T> onChange) {
    listener() => onChange(valueListenable.value);
    _valueListenableSubscriptions.putIfAbsent(valueListenable, () => []).add(listener);
    valueListenable.addListener(listener);
  }

  @Deprecated("use listenToValueChanges")
  void onValueChanged<T extends Object>(ValueListenable<T> valueListenable, TypedCallback<T> onChange) => listenToValueChanges;

  Future<void> removeValueListeners() async {
    for (var notifier in _valueListenableSubscriptions.keys) {
      for (var listener in _valueListenableSubscriptions[notifier]!) {
        notifier.removeListener(listener);
      }
    }
  }

  @Deprecated("use removeValueListeners")
  void removeListeners() => removeValueListeners;
}
