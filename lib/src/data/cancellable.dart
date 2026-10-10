import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/src/functions.dart';

/// Callback invoked for each observed value.
///
/// The `value` parameter is the stream event or the listenable value at the
/// moment of notification. Returning `false` stops the registration.
typedef ListenableValueMapper<T> = FutureOr<Any> Function(T value);

/// Receives errors raised by a cancellable source stream or mapper.
typedef CancellableErrorHandler = void Function(Object error, StackTrace stackTrace);

/// Chooses which notifications of a listenable reach a slow asynchronous mapper.
enum ListenableDelivery {
  /// Every notification runs the mapper once, in order.
  every,

  /// Notifications that arrived while the mapper was running are collapsed:
  /// only the newest one runs the mapper next.
  latest,
}

/// Represents a resource or workflow that can be cancelled.
abstract interface class Cancellable {
  /// Stops further processing and releases any attached listeners/subscriptions.
  void cancel();
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

  /// Active subscription to [stream].
  late final StreamSubscription<void> subscription;

  /// Creates a cancellable stream listener and starts listening immediately.
  StreamCancellable(this.stream, this.mapper, {super.onError, super.onCancel}) {
    subscription = stream.asyncMap(_map).listen(null, onError: _handleError, onDone: _finishAndReportErrors);
    attachCancellation(subscription.cancel);
  }

  @override
  String get _errorContext => 'while processing a cancellable stream callback';

  Future<void> _map(T event) async {
    if (!isCancelled) {
      await _runMapper(() => mapper(event));
    }
  }
}

/// Bridges a [Listenable] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each notification and once immediately on
/// creation. Calls never overlap; [delivery] decides what happens to
/// notifications that arrive while a call is running. Returning `false` from
/// [mapper] cancels this instance.
class NotifierCancellable extends _QueuedCancellable<void> {
  /// Listenable to observe.
  final Listenable notifier;

  /// Callback invoked on every notification.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedResult<Any> mapper;

  /// Creates a cancellable notifier listener and triggers initial mapping once.
  NotifierCancellable(this.notifier, this.mapper, {super.delivery, super.onError, super.onCancel}) : super(notifier);

  @override
  String get _errorContext => 'while processing a cancellable notifier callback';

  @override
  void _read() {}

  @override
  FutureOr<Any> _invoke(void _) => mapper();
}

/// Bridges a [ValueListenable] into a cancellable async callback pipeline.
///
/// The [mapper] is invoked for each value update and once immediately with the
/// current value. Calls never overlap; [delivery] decides what happens to
/// values that arrive while a call is running. Returning `false` from [mapper]
/// cancels this instance.
class ListenableCancellable<T> extends _QueuedCancellable<T> {
  /// Value listenable to observe.
  final ValueListenable<T> listenable;

  /// Callback invoked on every value change.
  ///
  /// Return `false` to cancel further listening.
  final AsyncOrTypedCallback<Any, T> mapper;

  /// Creates a cancellable value-listenable listener and maps current value once.
  ListenableCancellable(this.listenable, this.mapper, {super.delivery, super.onError, super.onCancel}) : super(listenable);

  @override
  String get _errorContext => 'while processing a cancellable value-listenable callback';

  @override
  T _read() => listenable.value;

  @override
  FutureOr<Any> _invoke(T value) => mapper(value);
}

/// Owns the cancellable registrations of one owner and cancels them together.
///
/// [BlocListenables] and [StateListenable] delegate to it. Other owners
/// (controllers, services) can hold one directly and call [cancelAll] or
/// [cancelAllAndWait] from their own disposal.
///
/// Registrations that finish on their own (a completed stream, a mapper that
/// returned `false`) leave the registry immediately. Registrations created
/// after the registry was closed are cancelled at once and never call their
/// mapper.
class CancellableRegistry {
  final List<Cancellable> _registrations = [];
  bool _isClosed = false;

  /// Whether [cancelAll] or [cancelAllAndWait] has been called.
  bool get isClosed => _isClosed;

  /// Number of active registrations.
  int get length => _registrations.length;

  /// Subscribes to [stream] and invokes [mapper] for each emitted value.
  ///
  /// Returning `false` from [mapper] stops the registration. Source and mapper
  /// errors go to [onError], or to [FlutterError.reportError] without it.
  Cancellable onStreamChange<T>(Stream<T> stream, ListenableValueMapper<T> mapper, {CancellableErrorHandler? onError}) {
    return track((onCancel) => StreamCancellable(stream, mapper, onError: onError, onCancel: onCancel));
  }

  /// Observes [listenable] and invokes [mapper] for its current and future values.
  ///
  /// See [ListenableDelivery] for slow asynchronous mappers.
  Cancellable onValueChanged<T>(
    ValueListenable<T> listenable,
    ListenableValueMapper<T> mapper, {
    ListenableDelivery delivery = ListenableDelivery.every,
    CancellableErrorHandler? onError,
  }) {
    return track((onCancel) => ListenableCancellable(listenable, mapper, delivery: delivery, onError: onError, onCancel: onCancel));
  }

  /// Observes [listenable] and invokes [mapper] immediately and for every change.
  ///
  /// See [ListenableDelivery] for slow asynchronous mappers.
  Cancellable onAnyChange(
    Listenable listenable,
    AsyncOrTypedResult<Any> mapper, {
    ListenableDelivery delivery = ListenableDelivery.every,
    CancellableErrorHandler? onError,
  }) {
    return track((onCancel) => NotifierCancellable(listenable, mapper, delivery: delivery, onError: onError, onCancel: onCancel));
  }

  /// Disposes [notifier] together with this registry and returns it.
  ///
  /// Useful for derived listenables created by the owner, for example
  /// `late final label = own(source.mapValue(format))`. A notifier passed to a
  /// closed registry is disposed immediately.
  T own<T extends ChangeNotifier>(T notifier) {
    track(
      (onCancel) => _CallbackCancellable(() {
        onCancel();
        notifier.dispose();
      }),
    );
    return notifier;
  }

  /// Registers a cancellable built by [create].
  ///
  /// [create] receives the callback that removes the registration; the
  /// cancellable must call it once when it finishes or is cancelled.
  Cancellable track(Cancellable Function(VoidCallback onCancel) create) {
    Cancellable? cancellable;
    var finished = false;
    cancellable = create(() {
      finished = true;
      _registrations.remove(cancellable);
    });
    if (_isClosed) {
      cancellable.cancel();
    } else if (!finished) {
      _registrations.add(cancellable);
    }
    return cancellable;
  }

  /// Closes the registry and cancels every registration without waiting for
  /// asynchronous resource cleanup.
  void cancelAll() {
    for (final registration in _close()) {
      registration.cancel();
    }
  }

  /// Closes the registry, cancels every registration and waits until their
  /// resources are released.
  ///
  /// Every registration is attempted. The first failure is rethrown with its
  /// stack trace; the others are reported through [FlutterError.reportError].
  Future<void> cancelAllAndWait() async {
    final failures = <(Object, StackTrace)>[];
    await Future.wait(
      _close().map((registration) async {
        try {
          await registration.cancelAndWait();
        } on Object catch (error, stackTrace) {
          failures.add((error, stackTrace));
        }
      }),
    );
    if (failures.isEmpty) {
      return;
    }
    for (final (error, stackTrace) in failures.skip(1)) {
      _reportError(error, stackTrace, 'while cancelling registrations');
    }
    final (error, stackTrace) = failures.first;
    Error.throwWithStackTrace(error, stackTrace);
  }

  List<Cancellable> _close() {
    _isClosed = true;
    final registrations = List<Cancellable>.of(_registrations);
    _registrations.clear();
    return registrations;
  }
}

abstract class _CancellableBase implements Cancellable {
  _CancellableBase({this.onError, this.onCancel});

  /// Receives source and mapper errors instead of leaving them unhandled.
  final CancellableErrorHandler? onError;

  final VoidCallback? onCancel;

  bool _isCancelled = false;
  Future<void> Function()? _cancelResources;
  Future<void>? _cancellation;
  bool _isCancellationAwaited = false;

  bool get isCancelled => _isCancelled;

  String get _errorContext;

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

  Future<void> _runMapper(AsyncOrTypedResult<Any> call) async {
    try {
      final shouldContinue = await call();
      if (!isCancelled && shouldContinue == false) {
        _finishAndReportErrors();
      }
    } on Object catch (error, stackTrace) {
      _handleError(error, stackTrace);
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
    _reportError(error, stackTrace, _errorContext);
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
    _reportError(error, stackTrace, 'while cancelling a listenable registration');
  }

  void _finishAndReportErrors() {
    try {
      cancel();
    } on Object catch (error, stackTrace) {
      _reportCancellationError(error, stackTrace);
    }
  }
}

/// Serializes mapper calls for a [Listenable] through an internal queue.
abstract class _QueuedCancellable<T> extends _CancellableBase {
  _QueuedCancellable(this._source, {this.delivery = ListenableDelivery.every, super.onError, super.onCancel}) {
    _source.addListener(_enqueue);
    _subscription = _events.stream.asyncMap(_map).listen(null, onError: _handleError);
    attachCancellation(() async {
      _source.removeListener(_enqueue);
      await _subscription.cancel();
      await _events.close();
    });
    _enqueue();
  }

  /// Which queued notifications reach the mapper.
  final ListenableDelivery delivery;

  final Listenable _source;
  final StreamController<(int, T)> _events = StreamController();
  late final StreamSubscription<void> _subscription;
  int _lastEventId = 0;

  /// Reads the value delivered with a notification.
  T _read();

  FutureOr<Any> _invoke(T value);

  Future<void> _map((int, T) event) async {
    final (id, value) = event;
    if (isCancelled || (delivery == ListenableDelivery.latest && id != _lastEventId)) {
      return;
    }
    await _runMapper(() => _invoke(value));
  }

  void _enqueue() {
    if (!isCancelled && !_events.isClosed) {
      _events.add((++_lastEventId, _read()));
    }
  }
}

class _CallbackCancellable implements Cancellable {
  _CallbackCancellable(this._onCancel);

  VoidCallback? _onCancel;

  @override
  void cancel() {
    final onCancel = _onCancel;
    _onCancel = null;
    onCancel?.call();
  }
}

void _reportError(Object error, StackTrace stackTrace, String context) {
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stackTrace, library: 'flutter_commons', context: ErrorDescription(context)),
  );
}

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
