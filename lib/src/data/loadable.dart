import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

@immutable
final class Loadable<T> {
  final bool isLoading;
  final T? _value;
  final Object? error;
  final StackTrace? stack;

  final ValueGetter<T>? defaultBuilder;

  T? get value => _value;

  T? get v => _value ?? defaultBuilder?.call();

  T get requireValue => require(v);

  T get rv => requireValue;

  Object get requireError => error!;

  Object get re => error!;

  Object? get e => error;

  StackTrace get requireStacktrace => stack ?? StackTrace.current;

  StackTrace get rst => requireStacktrace;

  StackTrace? get st => stack;

  bool get hasError => error != null;

  bool get hasValue => value != null;

  bool get inProgress => isLoading;

  bool get isWorking => isLoading;

  const Loadable.idle({this.defaultBuilder})
      : isLoading = false,
        _value = null,
        error = null,
        stack = null;

  const Loadable.loading({this.defaultBuilder})
      : isLoading = true,
        _value = null,
        error = null,
        stack = null;

  const Loadable.error(this.error, [this.stack])
      : isLoading = false,
        _value = null,
        defaultBuilder = null;

  const Loadable(
    this._value, {
    this.isLoading = false,
    this.error,
    this.stack,
    this.defaultBuilder,
  });

  @override
  String toString() {
    return 'Loadable{${isLoading ? 'loading' : 'idle'}, ${value == null ? 'nothing' : value.runtimeType}, error: ${error ?? ''}}';
  }

  Loadable<T> loading() => Loadable(value, isLoading: true, error: error, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<T> idle() => Loadable(value, isLoading: false, error: error, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<T> result([T? value]) => Loadable(value, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<X> change<X>(X? value, {ValueGetter<X>? defaultBuilder}) =>
      Loadable(value, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<T> clearResult() => Loadable(null, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<T> fail(Object ex, [StackTrace? stack]) => Loadable(value, isLoading: isLoading, error: ex, stack: stack, defaultBuilder: defaultBuilder);

  Loadable<T> clearError() => Loadable(value, isLoading: isLoading, error: null, defaultBuilder: defaultBuilder, stack: stack);

  Loadable<T> clear({bool error = true, bool value = true, bool loading = true}) => Loadable(value ? null : this.value,
      isLoading: loading ? false : this.isLoading, error: error ? null : this.error, defaultBuilder: defaultBuilder, stack: stack);

  T valueOr(T other) => value ?? other;

  ValueKey generateKey({
    bool includeValue = true,
    bool includeLoading = true,
  }) {
    return ValueKey('${includeLoading ? '$isLoading' : ''};$error;$stack;${includeValue ? '$value' : '$hasValue'}');
  }

  Loadable copyWith({
    bool? isLoading,
    T? value,
    Object? error,
    StackTrace? stack,
    ValueGetter<T>? defaultBuilder,
  }) {
    return Loadable(
      value ?? this._value,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      stack: stack ?? this.stack,
      defaultBuilder: defaultBuilder ?? this.defaultBuilder,
    );
  }
}

extension LoadableExt<T> on T {
  Loadable<T> get asLoadable => Loadable(this);

  Loadable<T> get asValue => Loadable(this);
}
