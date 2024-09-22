import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef QueryFailCallback<T> = FutureOr<QueryRetry> Function(QueryRequest<T> request, Object exception, int retries);

enum QueryPriority {
  immediate,
  critical,
  highest,
  high,
  aboveNormal,
  normal,
  belowNormal,
  low,
  ;
}

class QueryScheduler with Logging implements Disposable {
  bool _isPaused = false;
  bool _isLooping = false;

  final Map<QueryPriority, List<QueryRequest>> _requests = {};

  Iterable<QueryPriority> get _keysWithRequests => _requests.keys.where((key) => require(_requests[key]).isNotEmpty);

  final QueryFailCallback? onFail;

  QueryScheduler({
    this.onFail,
  }) {
    for (var priority in QueryPriority.values) {
      _requests.putIfAbsent(priority, () => []);
    }
  }

  void start() {
    _isPaused = false;
    _loop();
  }

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
        if (result == QueryRetry.reschedule) {
          requests.add(request);
        }
      }
    } finally {
      _isLooping = false;
    }
  }

  void drop({final Iterable<String> tags = const [], final Iterable<int> ids = const []}) {
    List<QueryRequest> requests = [];

    if (tags.isEmpty && ids.isEmpty) {
      requests = Map.of(_requests).values.fold([], (previousValue, element) => [...previousValue, ...element]);
      _requests.clear();
      return;
    }

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

    for (var request in requests) {
      trace('request #${request.id} dropped');
      request.completer.completeError(CancelledQueryException());
    }
  }

  QueryRequest<T> enqueue<T>(
    AsyncValueGetter<T> request, {
    QueryPriority priority = QueryPriority.low,
    String? tag,
    QueryFailCallback? onFail,
  }) {
    if (_isPaused) {
      warn('scheduler is paused; request will be added in queue');
    }

    QueryRequest<T> rq = QueryRequest<T>(
      request: request,
      tag: tag,
      onFail: onFail ?? this.onFail,
    );
    trace('scheduling request #${rq.id} / ${priority.name}');
    if (priority == QueryPriority.immediate) {
      _execute(rq);
    } else {
      require(_requests[priority]).add(rq);
      _loop();
    }

    return rq;
  }

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

    Loadable result = const Loadable.loading();
    while (request.canTry) {
      try {
        trace('executing request #${request.id}; r${request.tries}');
        request.tries++;
        result = result.result(await request.request());
        break;
      } catch (ex, stack) {
        result = result.fail(ex, stack);
        final retryResult = await request.onFail?.call(request, ex, request.tries);
        switch (retryResult) {
          case QueryRetry.retry:
            request.maxRetries++;
            continue;
          case QueryRetry.reschedule:
          case QueryRetry.drop:
            return retryResult!;
          default:
            if (request.canTry) {
              continue;
            }
            break;
        }
      }
    }

    if (!request.completer.isCompleted) {
      if (result.hasError) {
        request.completer.completeError(result.requireError, result.stack);
      } else {
        request.completer.complete(result.value);
      }
    }

    return QueryRetry.drop;
  }
}

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
  })  : maxRetries = maxRetries ?? defaultRetries,
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
