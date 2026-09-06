import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef ListenableValueMapper<T> = FutureOr<Any> Function(T value);

/// Adds cancellable stream and listenable registrations to a [Bloc].
mixin BlocListenables<S, E> on Bloc<S, E> {
  final List<Cancellable> _subscriptions = [];
  bool _isClosing = false;
  Future<void>? _closing;

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
    if (_isClosing || isClosed) {
      cancellable.cancel();
    } else if (!finished) {
      _subscriptions.add(cancellable);
    }
    return cancellable;
  }

  @override
  Future<void> close() => _closing ??= _closeListenables(() => super.close());

  Future<void> _closeListenables(Future<void> Function() closeBloc) async {
    _isClosing = true;
    final subscriptions = List<Cancellable>.of(_subscriptions);
    _subscriptions.clear();
    final failures = <(Object, StackTrace)>[];
    await Future.wait(
      subscriptions.map((subscription) async {
        try {
          await subscription.cancelAndWait();
        } on Object catch (error, stackTrace) {
          failures.add((error, stackTrace));
        }
      }),
    );
    try {
      await closeBloc();
    } on Object catch (error, stackTrace) {
      failures.add((error, stackTrace));
    }
    if (failures.isNotEmpty) {
      for (final (error, stackTrace) in failures.skip(1)) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'flutter_commons',
            context: ErrorDescription('while closing BLoC listenable registrations'),
          ),
        );
      }
      final (error, stackTrace) = failures.first;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
