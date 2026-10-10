import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_commons/src/data/loadable.dart';

/// A derived [ValueListenable] that maps every value of [source] through [mapper].
///
/// It listens to [source] only while it has listeners of its own. Removing the
/// last listener detaches it, so a chain such as `a.mapValue(f).mapValue(g)`
/// leaves no listener on `a` once nobody listens to the tail, and its links are
/// not retained by `a` even if nobody disposes them. Calling [dispose] is still
/// supported and detaches immediately.
///
/// While detached, [value] is computed from `source.value` on every read, so
/// [mapper] should be pure and cheap. Listeners are notified only when the
/// mapped value changes according to `==`.
class MappedValueListenable<X, Y> extends ChangeNotifier implements ValueListenable<Y> {
  /// Source value listenable.
  final ValueListenable<X> source;

  /// Mapping function converting source value into output value.
  final Y Function(X value) mapper;

  /// Creates a mapped listenable. [mapper] runs on the first read or listener.
  MappedValueListenable(this.source, this.mapper);

  late Y _value;
  bool _isAttached = false;
  bool _isDisposed = false;

  /// Current mapped value.
  @override
  Y get value => _isAttached ? _value : mapper(source.value);

  @override
  void addListener(VoidCallback listener) {
    if (_isAttached || _isDisposed) {
      super.addListener(listener);
      return;
    }
    // Map before registering, so a throwing mapper leaves neither this listener
    // nor a source subscription behind.
    final value = mapper(source.value);
    super.addListener(listener);
    _value = value;
    source.addListener(_onSourceChanged);
    _isAttached = true;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _detachIfUnused();
  }

  /// Detaches from [source] and releases listeners.
  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _detach();
    super.dispose();
  }

  void _onSourceChanged() {
    final next = mapper(source.value);
    if (next == _value) {
      return;
    }

    _value = next;
    notifyListeners();
    // A listener removed during notifyListeners is only dropped once the
    // notification finishes, so removeListener could not detach then.
    _detachIfUnused();
  }

  void _detachIfUnused() {
    if (!hasListeners) {
      _detach();
    }
  }

  void _detach() {
    if (_isAttached) {
      source.removeListener(_onSourceChanged);
      _isAttached = false;
    }
  }
}

/// A derived [ValueListenable] that maps values of [source] through an
/// asynchronous [mapper] and exposes the progress as a [Loadable].
///
/// - Before the first listener the value is [Loadable.idle].
/// - While a call is pending the value is the previous one marked as loading.
/// - A result replaces the value and clears the error; a failure keeps the
///   previous value and stores the error with its stack trace.
/// - Only the call for the latest source value is applied: results of calls
///   started for older values are dropped, whatever order they complete in.
/// - A synchronous [mapper] result is applied without a loading state.
///
/// Like [MappedValueListenable], it listens to [source] only while it has
/// listeners. Detaching drops the pending call and keeps the last value;
/// attaching again maps the current source value. The state reached while
/// attaching is announced in a microtask, because a listener such as
/// `ValueListenableBuilder` subscribes from `initState`, where a synchronous
/// notification would call `setState` too early.
class AsyncMappedValueListenable<X, Y> extends ChangeNotifier implements ValueListenable<Loadable<Y>> {
  /// Source value listenable.
  final ValueListenable<X> source;

  /// Mapping function converting source value into output value.
  final FutureOr<Y> Function(X value) mapper;

  /// Creates an asynchronously mapped listenable. [mapper] runs once it has a listener.
  AsyncMappedValueListenable(this.source, this.mapper);

  Loadable<Y> _value = const Loadable.idle();
  int _generation = 0;
  bool _isAttached = false;
  bool _isDisposed = false;

  /// Current mapping state.
  @override
  Loadable<Y> get value => _value;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_isAttached || _isDisposed) {
      return;
    }
    source.addListener(_onSourceChanged);
    _isAttached = true;
    _map(notify: false);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _detachIfUnused();
  }

  /// Detaches from [source], drops the pending call and releases listeners.
  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _detach();
    super.dispose();
  }

  void _onSourceChanged() => _map(notify: true);

  void _map({required bool notify}) {
    final generation = ++_generation;
    final FutureOr<Y> result;
    try {
      result = mapper(source.value);
    } on Object catch (error, stackTrace) {
      _emit(_value.fail(error, stackTrace).idle(), notify: notify);
      return;
    }

    if (result is! Future<Y>) {
      _emit(Loadable<Y>(result), notify: notify);
      return;
    }

    _emit(_value.clearError().loading(), notify: notify);
    result
        .then<void>(
          (value) {
            if (generation == _generation) {
              _emit(Loadable<Y>(value), notify: true);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (generation == _generation) {
              _emit(_value.fail(error, stackTrace).idle(), notify: true);
            }
          },
        )
        .ignore();
  }

  void _emit(Loadable<Y> next, {required bool notify}) {
    _value = next;
    if (!notify) {
      final generation = _generation;
      scheduleMicrotask(() {
        if (_isAttached && generation == _generation) {
          _notifyAndDetachIfUnused();
        }
      });
      return;
    }
    _notifyAndDetachIfUnused();
  }

  void _notifyAndDetachIfUnused() {
    notifyListeners();
    // A listener removed during notifyListeners is only dropped once the
    // notification finishes, so removeListener could not detach then.
    _detachIfUnused();
  }

  void _detachIfUnused() {
    if (!hasListeners) {
      _detach();
    }
  }

  void _detach() {
    if (!_isAttached) {
      return;
    }
    source.removeListener(_onSourceChanged);
    _isAttached = false;
    _generation++;
    if (_value.isLoading) {
      _value = _value.idle();
    }
  }
}

extension ValueListenableMapExt<X> on ValueListenable<X> {
  /// Maps this listenable into a derived listenable with another value type.
  ///
  /// The result listens to this listenable only while it has listeners, so
  /// chained links do not need to be disposed. See [MappedValueListenable].
  MappedValueListenable<X, Y> mapValue<Y>(Y Function(X value) mapper) => MappedValueListenable<X, Y>(this, mapper);

  /// Maps this listenable through an asynchronous [mapper], keeping only the
  /// result for the latest value. See [AsyncMappedValueListenable].
  AsyncMappedValueListenable<X, Y> mapValueAsync<Y>(FutureOr<Y> Function(X value) mapper) => AsyncMappedValueListenable<X, Y>(this, mapper);
}
