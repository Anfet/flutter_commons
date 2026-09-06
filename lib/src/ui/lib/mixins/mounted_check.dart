import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Public mixin MountedCheck.
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

  /// Запрашивает обновление состояния. Использовать можно, если изменения провоцируют переменные, которые вставлять в setState неразумно
  ///
  /// например, если в результате `await longLastingOp` меняеются данные
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
