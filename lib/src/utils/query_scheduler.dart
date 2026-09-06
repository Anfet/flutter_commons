import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef QueryFailCallback<T> = FutureOr<QueryRetry> Function(QueryRequest<T> request, Object exception, int retries);

/// Priority levels used by [QueryScheduler].
enum QueryPriority {
  immediate,
  critical,
  highest,
  high,
  aboveNormal,
  normal,
  belowNormal,
  low,
}

/// Sequential request scheduler with priority queues and retry support.
class QueryScheduler implements Disposable {
  bool _isPaused = false;
  bool _isLooping = false;

  final Map<QueryPriority, List<QueryRequest>> _requests = {};
  final Set<QueryRequest> _inFlight = {};

  Iterable<QueryPriority> get _keysWithRequests => _requests.keys.where((key) => require(_requests[key]).isNotEmpty);

  final QueryFailCallback? onFail;

  QueryScheduler({
    this.onFail,
  }) {
    for (var priority in QueryPriority.values) {
      _requests.putIfAbsent(priority, () => []);
    }
  }

  /// Starts processing queued requests.
  void start() {
    _isPaused = false;
    _loop();
  }

  /// Pauses processing loop.
  void pause() => _isPaused = true;

  @override
  void dispose() => drop();

  Future<void> _loop() async {
    if (_isLooping) {
      return;
    }
    _isLooping = true;
    try {
      while (!_isPaused) {
        var keys = _keysWithRequests;
        if (keys.isEmpty) {
          break;
        }

        var requests = require(_requests[keys.first]);
        var request = requests.first;
        QueryRetry result = QueryRetry.drop;
        if (!request.completer.isCompleted) {
          result = await _execute(request);
        }

        requests.remove(request);
        if (result == QueryRetry.reschedule && !request.completer.isCompleted && request.canTry) {
          requests.add(request);
        }
      }
    } finally {
      _isLooping = false;
    }
  }

  /// Drops queued requests optionally filtered by [tags] or [ids].
  ///
  /// Dropped requests are completed with [CancelledQueryException].
  void drop({final Iterable<String> tags = const [], final Iterable<int> ids = const []}) {
    final requests = <QueryRequest>{..._inFlight};

    if (tags.isEmpty && ids.isEmpty) {
      requests.addAll(_requests.values.expand((requests) => requests));
      for (var priority in QueryPriority.values) {
        _requests[priority]?.clear();
      }
    } else {
      var keys = _keysWithRequests;
      for (var key in keys) {
        var list = _requests[key] ?? [];
        list.removeWhere(
          (request) {
            var doRemove = tags.contains(request.tag) || ids.contains(request.id);
            if (doRemove) {
              requests.add(request);
            }
            return doRemove;
          },
        );
      }
      requests.removeWhere((request) => !tags.contains(request.tag) && !ids.contains(request.id));
    }

    for (var request in requests) {
      _completeCancelled(request);
    }
  }

  /// Enqueues a request and returns a handle that can be awaited or filtered.
  QueryRequest<T> enqueue<T>(
    AsyncValueGetter<T> request, {
    QueryPriority priority = QueryPriority.low,
    String? tag,
    QueryFailCallback? onFail,
  }) {
    QueryRequest<T> rq = QueryRequest<T>(
      request: request,
      tag: tag,
      onFail: onFail ?? this.onFail,
    );
    if (priority == QueryPriority.immediate) {
      _executeImmediate(rq);
    } else {
      require(_requests[priority]).add(rq);
      _loop();
    }

    return rq;
  }

  /// Enqueues a request and returns its future result.
  Future<T> get<T>(
    AsyncValueGetter<T> request, {
    QueryPriority priority = QueryPriority.low,
    String? tag,
    QueryFailCallback? onFail,
  }) {
    var rq = enqueue(request, tag: tag, priority: priority, onFail: onFail);
    return rq.future;
  }

  Future<QueryRetry> _execute(QueryRequest request) async {
    if (request.completer.isCompleted) {
      return QueryRetry.drop;
    }

    _inFlight.add(request);
    try {
      while (request.canTry && !request.completer.isCompleted) {
        try {
          request.tries++;
          final value = await request.request();
          _completeSuccess(request, value);
          return QueryRetry.drop;
        } catch (error, stack) {
          if (request.completer.isCompleted) {
            return QueryRetry.drop;
          }

          QueryRetry? action;
          try {
            action = await request.onFail?.call(request, error, request.tries);
          } catch (onFailError, onFailStack) {
            _completeFailure(request, onFailError, onFailStack);
            return QueryRetry.drop;
          }

          switch (action) {
            case QueryRetry.retry:
              if (request.canTry) {
                continue;
              }
              _completeFailure(request, error, stack);
              return QueryRetry.drop;
            case QueryRetry.reschedule:
              if (request.canTry) {
                return QueryRetry.reschedule;
              }
              _completeFailure(request, error, stack);
              return QueryRetry.drop;
            case QueryRetry.fail:
              _completeFailure(request, error, stack);
              return QueryRetry.drop;
            case QueryRetry.drop:
              _completeCancelled(request);
              return QueryRetry.drop;
            case null:
              if (request.canTry) {
                continue;
              }
              _completeFailure(request, error, stack);
              return QueryRetry.drop;
          }
        }
      }
      _completeFailure(request, StateError('Query request has no retry capacity'), StackTrace.current);
      return QueryRetry.drop;
    } finally {
      _inFlight.remove(request);
    }
  }

  void _executeImmediate(QueryRequest request) {
    unawaited(
      _execute(request).then((result) {
        if (result == QueryRetry.reschedule && !request.completer.isCompleted && request.canTry) {
          require(_requests[QueryPriority.immediate]).add(request);
          _loop();
        }
      }),
    );
  }

  void _completeSuccess(QueryRequest request, Object? value) {
    if (!request.completer.isCompleted) {
      request.completer.complete(value);
    }
  }

  void _completeFailure(QueryRequest request, Object error, StackTrace stack) {
    if (!request.completer.isCompleted) {
      request.completer.completeError(error, stack);
    }
  }

  void _completeCancelled(QueryRequest request) {
    if (!request.completer.isCompleted) {
      request.completer.completeError(CancelledQueryException());
    }
  }
}

/// A queued request entry managed by [QueryScheduler].
class QueryRequest<T> {
  static int requestId = 0;
  static int defaultRetries = 3;

  final int id = requestId++;
  final Completer<T> completer = Completer();
  final AsyncValueGetter<T> request;
  final String? tag;

  int tries;

  ///кол-во повторных попыток запроса если ответ прервался с ошибкой. по дефолту устанавливается из [defaultRetries] = 3
  int maxRetries;

  ///вызывается, если запрос прерывается с ошибкой. В от
  QueryFailCallback<T>? onFail;

  Future<T> get future => completer.future;

  bool get canTry => tries < maxRetries;

  QueryRequest({
    required this.request,
    this.tag,
    int? tries,
    int? maxRetries,
    this.onFail,
  }) : maxRetries = maxRetries ?? defaultRetries,
       tries = 0;
}

///указывает на действие по повтору запроса
enum QueryRetry {
  ///попробовать еще раз
  retry,

  ///выбросить ошибку
  fail,

  ///полностью проигнорировать запрос
  drop,
  //попробовать еще раз, передвинув запрос в конец очереди
  reschedule,
}
