import 'dart:async';

/// A simple async mutex that serializes access to critical sections.
class Mutex {
  Future<void> _tail = Future<void>.value();
  var _pendingLocks = 0;

  /// Runs [future] exclusively after previous locks are completed.
  Future<T> lock<T>(Future<T> Function() future) {
    final previousRelease = _tail;
    final release = Completer<void>();
    _tail = release.future;
    _pendingLocks++;

    return _run(previousRelease, future, release);
  }

  Future<T> _run<T>(
    Future<void> previousRelease,
    Future<T> Function() future,
    Completer<void> release,
  ) async {
    try {
      await previousRelease;
      return await Future<T>.sync(future);
    } finally {
      _pendingLocks--;
      release.complete();
    }
  }

  /// Waits until there are no active lock owners.
  Future<void> whileBusy() => _tail;

  /// Whether the mutex currently has active or queued work.
  bool get isBusy => _pendingLocks > 0;
}
