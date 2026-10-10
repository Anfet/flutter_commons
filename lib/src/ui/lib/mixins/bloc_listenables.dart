import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Adds cancellable stream and listenable registrations to a [Bloc].
///
/// Every registration is cancelled when the Bloc closes; [close] waits until
/// their resources are released before closing the Bloc itself.
mixin BlocListenables<E, S> on Bloc<E, S> {
  final CancellableRegistry _registry = CancellableRegistry();
  Future<void>? _closing;

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

  /// Disposes [notifier] when this Bloc closes and returns it.
  T own<T extends ChangeNotifier>(T notifier) => _registry.own(notifier);

  @override
  Future<void> close() => _closing ??= _closeListenables(() => super.close());

  Future<void> _closeListenables(Future<void> Function() closeBloc) async {
    (Object, StackTrace)? failure;
    try {
      await _registry.cancelAllAndWait();
    } on Object catch (error, stackTrace) {
      failure = (error, stackTrace);
    }
    try {
      await closeBloc();
    } on Object catch (error, stackTrace) {
      if (failure == null) {
        failure = (error, stackTrace);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'flutter_commons',
            context: ErrorDescription('while closing BLoC listenable registrations'),
          ),
        );
      }
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure.$1, failure.$2);
    }
  }
}
