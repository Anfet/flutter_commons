import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/src/functions.dart';

/// Represents a resource or workflow that can be cancelled.
abstract interface class Cancellable {
  /// Stops further processing and releases any attached listeners/subscriptions.
  void cancel();
}

/// Receives errors raised by a cancellable source stream or mapper.
typedef CancellableErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Waits until cancellation of built-in cancellables has released their resources.
///
/// Custom [Cancellable] implementations remain supported. Their synchronous
/// [Cancellable.cancel] contract is preserved, so there is no asynchronous work
/// to await through this extension.
/// Built-in implementations wait for resource cleanup even if `onCancel`
/// throws, then complete with that original error and stack trace. Additional
/// cleanup errors are reported through [FlutterError.reportError].
extension CancellableCancellation on Cancellable {
  Future<void> cancelAndWait() {
    if (this case final _CancellableBase cancellable) {
      return cancellable._cancelAndWait();
    }
    cancel();
    return Future<void>.value();
  }
}

abstract class _CancellableBase implements Cancellable {
  _CancellableBase({this.onCancel});

  final VoidCallback? onCancel;

  bool _isCancelled = false;
  Future<void> Function()? _cancelResources;
  Future<void>? _cancellation;
  bool _isCancellationAwaited = false;

  bool get isCancelled => _isCancelled;

  Future<void> _cancelAndWait() async {
    _isCancellationAwaited = true;
    (Object, StackTrace)? failure;
    try {
      cancel();
    } on Object catch (error, stackTrace) {
      failure = (error, stackTrace);
    }
    try {
      await _cancellation;
    } on Object catch (error, stackTrace) {
      if (failure == null) {
        failure = (error, stackTrace);
      } else {
        _reportCancellationError(error, stackTrace);
      }
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure.$1, failure.$2);
    }
  }

  void attachCancellation(Future<void> Function() cancelResources) {
    _cancelResources = cancelResources;
    if (_isCancelled) {
      _startCancellation();
    }
  }

  @override
  void cancel() {
    if (_isCancelled) {
      return;
    }

    _isCancelled = true;
    try {
      onCancel?.call();
    } finally {
      _startCancellation();
    }
  }

  void _startCancellation() {
    final cancelResources = _cancelResources;
    if (_cancellation == null && cancelResources != null) {
      _cancellation = Future<void>.sync(cancelResources);
      unawaited(
        _cancellation!.then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            if (!_isCancellationAwaited) {
              _reportCancellationError(error, stackTrace);
            }
          },
        ),
      );
    }
  }

  void _reportCancellationError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_commons',
        context: ErrorDescription('while cancelling a listenable registration'),
      ),
    );
  }

  void _finishAndReportErrors() {
    try {
      cancel();
    } on Object catch (error, stackTrace) {
      _reportCancellationError(error, stackTrace);
    }
  }
}

/// Listens to a [Stream] and maps each event through [mapper].
///
/// If [mapper] returns `false`, this instance cancels its subscription.
/// Natural stream completion also finishes the registration and invokes
/// `onCancel` once, so owners can release completed registrations.
class StreamCancellable<T> extends _CancellableBase {
  /// Source stream to observe.
  final Stream<T> stream;

  /// Callback invoked for each source event.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedCallback<Any, T> mapper;

  /// Receives source and mapper errors instead of leaving them unhandled.
  final CancellableErrorHandler? onError;

  /// Active subscription to [stream].
  late final StreamSubscription<void> subscription;

  /// Creates a cancellable stream listener and starts listening immediately.
  StreamCancellable(this.stream, this.mapper, {this.onError, super.onCancel}) {
    subscription = stream.asyncMap(_map).listen(null, onError: _handleError, onDone: _finishAndReportErrors);
    attachCancellation(subscription.cancel);
  }

  Future<void> _map(T event) async {
    if (isCancelled) {
      return;
    }

    try {
      final shouldContinue = await mapper(event);
      if (!isCancelled && shouldContinue == false) {
        _finishAndReportErrors();
      }
    } on Object catch (error, stackTrace) {
      if (!isCancelled) {
        _handleError(error, stackTrace);
      }
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (isCancelled) {
      return;
    }
    final handler = onError;
    if (handler != null) {
      handler(error, stackTrace);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_commons',
        context: ErrorDescription('while processing a cancellable stream callback'),
      ),
    );
  }
}

/// Bridges a [ChangeNotifier] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each notifier update and once immediately on
/// creation. Returning `false` from [mapper] cancels this instance.
class NotifierCancellable extends _CancellableBase {
  static int _eventId = 0;

  /// Notifier to observe.
  final ChangeNotifier notifier;

  /// Internal event bridge used to serialize async [mapper] calls.
  final StreamController<int> _streamController = StreamController();

  /// Callback invoked on every notifier change.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedResult<Any> mapper;

  /// Receives mapper errors instead of leaving them unhandled.
  final CancellableErrorHandler? onError;

  late final StreamSubscription<void> _subscription;

  /// Creates a cancellable notifier listener and triggers initial mapping once.
  NotifierCancellable(this.notifier, this.mapper, {this.onError, super.onCancel}) {
    notifier.addListener(_enqueue);
    _subscription = _streamController.stream.asyncMap(_map).listen(null, onError: _handleError);
    attachCancellation(() async {
      notifier.removeListener(_enqueue);
      await _subscription.cancel();
      await _streamController.close();
    });
    _enqueue();
  }

  Future<void> _map(int _) async {
    if (isCancelled) {
      return;
    }

    try {
      final shouldContinue = await mapper();
      if (!isCancelled && shouldContinue == false) {
        _finishAndReportErrors();
      }
    } on Object catch (error, stackTrace) {
      if (!isCancelled) {
        _handleError(error, stackTrace);
      }
    }
  }

  void _enqueue() {
    if (!isCancelled && !_streamController.isClosed) {
      _streamController.add(++_eventId);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (isCancelled) {
      return;
    }
    final handler = onError;
    if (handler != null) {
      handler(error, stackTrace);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_commons',
        context: ErrorDescription('while processing a cancellable notifier callback'),
      ),
    );
  }
}

/// Bridges a [ValueListenable] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each value update and once immediately with the
/// current value. Returning `false` from [mapper] cancels this instance.
class ListenableCancellable<T> extends _CancellableBase {
  /// Value listenable to observe.
  final ValueListenable<T> listenable;

  /// Internal event bridge used to serialize async [mapper] calls.
  final StreamController<T> _streamController = StreamController();

  /// Callback invoked on every value change.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedCallback<Any, T> mapper;

  /// Receives mapper errors instead of leaving them unhandled.
  final CancellableErrorHandler? onError;

  late final StreamSubscription<void> _subscription;

  /// Creates a cancellable value-listenable listener and maps current value once.
  ListenableCancellable(this.listenable, this.mapper, {this.onError, super.onCancel}) {
    listenable.addListener(_enqueue);
    _subscription = _streamController.stream.asyncMap(_map).listen(null, onError: _handleError);
    attachCancellation(() async {
      listenable.removeListener(_enqueue);
      await _subscription.cancel();
      await _streamController.close();
    });
    _enqueue();
  }

  Future<void> _map(T event) async {
    if (isCancelled) {
      return;
    }

    try {
      final shouldContinue = await mapper(event);
      if (!isCancelled && shouldContinue == false) {
        _finishAndReportErrors();
      }
    } on Object catch (error, stackTrace) {
      if (!isCancelled) {
        _handleError(error, stackTrace);
      }
    }
  }

  void _enqueue() {
    if (!isCancelled && !_streamController.isClosed) {
      _streamController.add(listenable.value);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (isCancelled) {
      return;
    }
    final handler = onError;
    if (handler != null) {
      handler(error, stackTrace);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_commons',
        context: ErrorDescription('while processing a cancellable value-listenable callback'),
      ),
    );
  }
}
