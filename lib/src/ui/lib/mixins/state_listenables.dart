import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// State equivalent of [BlocListenables].
///
/// It observes streams and value/change notifiers, then cancels every active
/// registration when this state is disposed.
mixin StateListenable<W extends StatefulWidget> on State<W> {
  final CancellableRegistry _registry = CancellableRegistry();

  /// Active registrations, exposed only for lifecycle tests.
  @visibleForTesting
  int get debugActiveListenableCount => _registry.length;

  /// Subscribes to [stream] and invokes [mapper] for each emitted value.
  ///
  /// Returning `false` from [mapper] stops the registration.
  Cancellable onStreamChange<T>(Stream<T> stream, ListenableValueMapper<T> mapper, {CancellableErrorHandler? onError}) {
    return _registry.onStreamChange(stream, mapper, onError: onError);
  }

  /// Observes [listenable] and invokes [mapper] for its current and future values.
  Cancellable onValueChanged<T>(
    ValueListenable<T> listenable,
    ListenableValueMapper<T> mapper, {
    ListenableDelivery delivery = ListenableDelivery.every,
    CancellableErrorHandler? onError,
  }) {
    return _registry.onValueChanged(listenable, mapper, delivery: delivery, onError: onError);
  }

  /// Observes [listenable] and invokes [mapper] immediately and for every change.
  Cancellable onAnyChange(
    Listenable listenable,
    AsyncOrTypedResult<Any> mapper, {
    ListenableDelivery delivery = ListenableDelivery.every,
    CancellableErrorHandler? onError,
  }) {
    return _registry.onAnyChange(listenable, mapper, delivery: delivery, onError: onError);
  }

  /// Disposes [notifier] together with this state and returns it.
  T own<T extends ChangeNotifier>(T notifier) => _registry.own(notifier);

  @override
  void dispose() {
    _registry.cancelAll();
    super.dispose();
  }
}
