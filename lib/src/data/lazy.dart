import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Lazily initializes and caches a value on first access.
///
/// Calling this object computes the value once using [initializer] and returns
/// the same cached instance for subsequent calls.
class Lazy<T> {
  /// Cached value created by [initializer].
  T? instance;

  /// Factory used to create [instance] on first access.
  final ValueGetter<T> initializer;

  /// Creates a lazy wrapper over [initializer].
  Lazy(this.initializer);

  /// Returns cached value, initializing it on first call.
  T call() {
    instance ??= initializer();
    return require(instance);
  }
}
