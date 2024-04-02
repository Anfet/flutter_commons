import 'package:flutter/cupertino.dart';

mixin MountedStateMixin<S extends StatefulWidget> on State<S> {
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

  /**
   * Запрашивает обновление состояния. Использовать можно, если изменения провоцируют переменные, которые вставлять в setState неразумно
   */
  void markNeedsRebuild() => setState(() { });

  @Deprecated('Устарело. Лучше использовать setState')
  void setStateChecked(VoidCallback func) {
    if (mounted && !_disposed) {
      setState(func);
    }
  }
}
