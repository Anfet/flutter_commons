import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

@immutable
final class Loadable<T> {
  final bool isLoading;
  final T? value;
  final Object? error;
  final StackTrace? stack;

  T get requireValue => value!;

  Object get requireError => error!;

  StackTrace get requireStacktrace => stack ?? StackTrace.current;

  bool get hasError => error != null;

  bool get hasValue => value != null;

  bool get inProgress => isLoading;

  bool get inWorking => isLoading;

  const Loadable.idle()
      : isLoading = false,
        value = null,
        error = null,
        stack = null;

  const Loadable.loading()
      : isLoading = true,
        value = null,
        error = null,
        stack = null;

  const Loadable.error(this.error, [this.stack])
      : isLoading = false,
        value = null;

  const Loadable(this.value, {
    this.isLoading = false,
    this.error,
    this.stack,
  });

  @override
  String toString() {
    return 'Loadable{${isLoading ? 'loading' : 'idle'}, ${value == null ? 'nothing' : value.runtimeType}, error: ${error ?? ''}}';
  }

  Loadable<T> loading() => Loadable(value, isLoading: true, error: error);

  Loadable<T> idle() => Loadable(value, isLoading: false, error: error);

  Loadable<T> result([T? value]) => Loadable(value, isLoading: isLoading, error: error);

  Loadable<X> change<X>(X value) => Loadable(value, isLoading: isLoading, error: error);

  Loadable<T> clearResult() => Loadable(null, isLoading: isLoading, error: error);

  Loadable<T> fail(Object ex, [StackTrace? stack]) => Loadable(value, isLoading: isLoading, error: ex, stack: stack);

  Loadable<T> clearError() => Loadable(value, isLoading: isLoading, error: null);

  T valueOr(T other) => value ?? other;
}

extension LoadableExt<T> on T {
  Loadable<T> get asLoadable => Loadable(this);

  Loadable<T> get asValue => Loadable(this);
}
