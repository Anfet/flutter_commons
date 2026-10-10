import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Makes [setState] safe to call from async callbacks, listeners and timers.
///
/// After the state is unmounted or disposed, [setState] is ignored instead of
/// throwing, and [ifMounted] rejects late results with a [FlowException].
mixin MountedCheck<S extends StatefulWidget> on State<S> {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted && !_disposed) {
      super.setState(fn);
    }
  }

  /// Requests a rebuild after fields were changed outside [setState].
  ///
  /// Use it when wrapping the change in [setState] is awkward, for example
  /// when data changes as the result of `await longLastingOp()`.
  void markNeedsRebuild() => setState(nothing);

  /// Awaits [value] and returns it only while this state is still mounted.
  ///
  /// If [value] completes with an error, that source error is propagated before
  /// the mounted check, including when disposal happened while it was pending.
  Future<T> ifMounted<T>(FutureOr<T> value) async {
    final result = await value;
    if (mounted && !_disposed) {
      return result;
    }

    throw FlowException('Context not mounted');
  }
}
