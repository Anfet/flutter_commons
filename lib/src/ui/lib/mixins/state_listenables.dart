import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// State equivalent of [BlocListenables].
///
/// It observes streams and value/change notifiers, then cancels every active
/// registration when this state is disposed.
mixin StateListenable<W extends StatefulWidget> on State<W> {
  final List<Cancellable> _subscriptions = [];
  bool _isDisposed = false;

  /// Active registrations, exposed only for lifecycle tests.
  @visibleForTesting
  int get debugActiveListenableCount => _subscriptions.length;

  /// Subscribes to [stream] and invokes [mapper] for each emitted value.
  ///
  /// Returning `false` from [mapper] stops the registration.
  Cancellable onStreamChange<T>(Stream<T> stream, ListenableValueMapper<T> mapper) {
    return _track((onCancel) => StreamCancellable(stream, mapper, onCancel: onCancel));
  }

  /// Observes [listenable] and invokes [mapper] for its current and future values.
  Cancellable onValueChanged<T>(ValueListenable<T> listenable, ListenableValueMapper<T> mapper) {
    return _track((onCancel) => ListenableCancellable(listenable, mapper, onCancel: onCancel));
  }

  /// Observes [notifier] and invokes [mapper] immediately and for every change.
  Cancellable onAnyChange(ChangeNotifier notifier, AsyncOrTypedResult<Any> mapper) {
    return _track((onCancel) => NotifierCancellable(notifier, mapper, onCancel: onCancel));
  }

  Cancellable _track(Cancellable Function(VoidCallback onCancel) create) {
    Cancellable? cancellable;
    var finished = false;
    cancellable = create(() {
      finished = true;
      _subscriptions.remove(cancellable);
    });
    if (_isDisposed) {
      cancellable.cancel();
    } else if (!finished) {
      _subscriptions.add(cancellable);
    }
    return cancellable;
  }

  @override
  void dispose() {
    _isDisposed = true;
    final subscriptions = List<Cancellable>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
