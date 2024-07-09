import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/src/consts.dart';

mixin MountedCheck<S extends StatefulWidget> on State<S> {
  bool _disposed = false;

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

}
