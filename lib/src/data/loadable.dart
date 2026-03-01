import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

@immutable
/// Immutable state holder for async loading/result/error flows.
///
/// It can represent:
/// - idle state without active work;
/// - loading state;
/// - successful state with value;
/// - failed state with error and stack trace.
final class Loadable<T> {
  /// Indicates whether operation is currently in progress.
  final bool isLoading;
  final T? _value;

  /// Stored error, when present.
  final Object? error;

  /// Stack trace associated with [error].
  final StackTrace? stack;

  /// Lazy default value provider used by [v] when [_value] is null.
  final ValueGetter<T>? defaultBuilder;

  /// Raw stored value.
  T? get value => _value;

  /// Value or lazily built default value.
  T? get v => _value ?? defaultBuilder?.call();

  /// Non-null value accessor.
  T get requireValue => require(v);

  /// Shorthand for [requireValue].
  T get rv => requireValue;

  /// Non-null error accessor.
  Object get requireError => error!;

  /// Shorthand for [requireError].
  Object get re => error!;

  /// Shorthand for [error].
  Object? get e => error;

  /// Stack trace or current stack if missing.
  StackTrace get requireStacktrace => stack ?? StackTrace.current;

  /// Shorthand for [requireStacktrace].
  StackTrace get rst => requireStacktrace;

  /// Shorthand for [stack].
  StackTrace? get st => stack;

  /// Whether an error is present.
  bool get hasError => error != null;

  /// Whether value is present.
  bool get hasValue => value != null;

  /// Alias for [isLoading].
  bool get inProgress => isLoading;

  /// Alias for [isLoading].
  bool get isWorking => isLoading;

  /// Creates idle state without value or error.
  const Loadable.idle({this.defaultBuilder})
      : isLoading = false,
        _value = null,
        error = null,
        stack = null;

  /// Creates loading state without value or error.
  const Loadable.loading({this.defaultBuilder})
      : isLoading = true,
        _value = null,
        error = null,
        stack = null;

  /// Creates error state.
  const Loadable.error(this.error, [this.stack])
      : isLoading = false,
        _value = null,
        defaultBuilder = null;

  /// Creates a custom state with optional value/error/loading flags.
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

  /// Returns a copy marked as loading.
  Loadable<T> loading() => Loadable(value, isLoading: true, error: error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns a copy marked as idle.
  Loadable<T> idle() => Loadable(value, isLoading: false, error: error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns a copy with updated value.
  Loadable<T> result([T? value]) => Loadable(value, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns a typed copy with mapped value type.
  Loadable<X> change<X>(X? value, {ValueGetter<X>? defaultBuilder}) =>
      Loadable(value, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns a copy with cleared value.
  Loadable<T> clearResult() => Loadable(null, isLoading: isLoading, error: error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns a copy with assigned error.
  Loadable<T> fail(Object ex, [StackTrace? stack]) => Loadable(value, isLoading: isLoading, error: ex, stack: stack, defaultBuilder: defaultBuilder);

  /// Returns a copy with cleared error.
  Loadable<T> clearError() => Loadable(value, isLoading: isLoading, error: null, defaultBuilder: defaultBuilder, stack: stack);

  /// Clears selected state parts.
  Loadable<T> clear({bool error = true, bool value = true, bool loading = true}) => Loadable(value ? null : this.value,
      isLoading: loading ? false : isLoading, error: error ? null : this.error, defaultBuilder: defaultBuilder, stack: stack);

  /// Returns stored value or [other] fallback.
  T valueOr(T other) => value ?? other;

  /// Builds a [ValueKey] reflecting current state.
  ValueKey generateKey({
    bool includeValue = true,
    bool includeLoading = true,
  }) {
    return ValueKey('${includeLoading ? '$isLoading' : ''};$error;$stack;${includeValue ? '$value' : '$hasValue'}');
  }

  /// Creates a partial copy.
  Loadable copyWith({
    bool? isLoading,
    T? value,
    Object? error,
    StackTrace? stack,
    ValueGetter<T>? defaultBuilder,
  }) {
    return Loadable(
      value ?? _value,
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
