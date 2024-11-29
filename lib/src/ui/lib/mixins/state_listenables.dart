import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

///аналог [BlocListenables] для стейтов. ползволяет подписаться на стримы и Value/Change Notifier-ы, освобождает подписки после dispose
mixin StateListenable<W extends StatefulWidget> on State<W> {
  final List<Cancellable> _subscriptions = [];

  /// подписывается на поток и вызывает [mapper] при каждом эмите
  /// Если [mapper] возвращает [false], то слушание будет трервано
  Cancellable onStreamChange<T>(Stream<T> stream, ListenableValueMapper<T> mapper) {
    final cancellable = StreamCancellable(stream, mapper);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  Cancellable onValueChanged<T>(ValueListenable<T> listenable, ListenableValueMapper<T> mapper) {
    final cancellable = ListenableCancellable(listenable, mapper);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  Cancellable onAnyChange(ChangeNotifier notifier, AsyncOrTypedResult<Any> mapper) {
    final cancellable = NotifierCancellable(notifier, mapper);
    _subscriptions.add(cancellable);
    return cancellable;
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
