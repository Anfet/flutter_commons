import 'package:flutter/foundation.dart';
import 'package:siberian_core/siberian_core.dart';

mixin ValueListenableMixin {
  final Map<ValueListenable, List<VoidCallback>> _callbacks = {};

  ///добавлет [onChange] коллбек к указанному [listenable]
  ///возвращает коллбек который был добавлен
  ///чтобы с его помощью можно отменить подписку
  VoidCallback listenToValueChanges<T extends Object>(ValueListenable<T> listenable, TypedCallback<T> onChange, {bool notifyOnSubscribe = true}) {
    listener() => onChange(listenable.value);
    var listeners = _callbacks.putIfAbsent(listenable, () => []);
    listeners.add(listener);
    listenable.addListener(listener);
    if (notifyOnSubscribe) {
      onChange(listenable.value);
    }

    return listener;
  }

  @Deprecated("use listenToValueChanges")
  void onValueChanged<T extends Object>(ValueListenable<T> valueListenable, TypedCallback<T> onChange) => listenToValueChanges;

  //удаляется все зарегистрированные коллбеки из указанных или текущих слушателей
  Future<void> removeValueListeners({List<ValueListenable>? listenables}) async {
    var list = List.of(listenables ?? _callbacks.keys);
    for (var listenable in list) {
      var callbacks = List.of(_callbacks[listenable]!);
      for (var callback in callbacks) {
        removeListener(callback, from: listenable);
      }
    }
  }

  @Deprecated("use removeValueListeners")
  void removeListeners() => removeValueListeners;

  ///удаляет [callback]  из списка наблюдения указанного [listenable]
  void removeListener(VoidCallback callback, {ValueListenable? from}) {
    final ValueListenable? listenable = from ?? _callbacks.keys.firstIf((it) => _callbacks[it]?.any((func) => func == callback) == true);
    if (listenable == null) {
      return;
    }

    listenable.removeListener(callback);
    var callbacks = _callbacks[listenable] ?? [];
    callbacks.remove(callback);
    if (callbacks.isEmpty) {
      _callbacks.remove(listenable);
    }
  }
}
