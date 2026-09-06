import 'dart:async';
import 'dart:collection';

import 'package:flutter_commons/flutter_commons.dart';

typedef PagedLoaderCallback<T, A> = Future<List<T>> Function(int page, int itemsPerPage, [A? arguments]);

/// Loads paged data on demand and keeps accumulated items in memory.
///
/// Only successful page data is cached. A request error is exposed through
/// [stream] and [hasError], without becoming part of [items]. Each request that
/// remains current emits exactly two states: loading followed by either content
/// or error. Calling [clear] or [dispose] invalidates any request already in
/// flight; its future still completes for its caller, but its result cannot
/// update this loader or emit a terminal state.
class PagedLoader<T, A> {
  final StreamController<Loadable<List<T>>> _streamController = StreamController.broadcast();
  Stream<Loadable<List<T>>> get stream => _streamController.stream;

  Loadable<List<T>> _lce = Loadable.idle();

  final int itemsPerPage;
  final int initialPage;
  final PagedLoaderCallback<T, A> onDemand;
  final TypedResultCallback<A, int>? onBuildArguments;

  final SplayTreeMap<int, List<T>> _pages = SplayTreeMap<int, List<T>>();

  int get lastPageLoaded => _pages.keys.last;
  int get nextPageToBeLoaded => (_pages.keys.lastOrNull ?? (initialPage - 1)) + 1;

  bool get didLoadAnything => _pages.isNotEmpty;

  bool get didReachEnd => _endReached;

  bool get isLoading => _lce.isLoading;
  bool get hasError => _lce.hasError;

  List<T> get items => [for (final page in _pages.values) ...page];

  bool _endReached = false;
  int _generation = 0;
  bool _isDisposed = false;

  PagedLoader({
    required this.itemsPerPage,
    required this.onDemand,
    this.onBuildArguments,
    this.initialPage = 0,
  });

  /// Clears loaded pages and resets pagination state to the initial page.
  void clear() {
    _generation++;
    _pages.clear();
    _endReached = false;

    _emit(Loadable.idle());
  }

  /// Loads the next page unless loading is already in progress or the end is reached.
  ///
  /// Returns loaded page items. Loading an explicit historical page replaces
  /// its cached data but does not change [didReachEnd]. End detection belongs
  /// to the page that was next when this request started.
  Future<List<T>> loadPage({int? page}) async {
    if ((page == null && _endReached) || isLoading || _isDisposed) {
      return [];
    }

    final requestGeneration = _generation;
    final nextPage = nextPageToBeLoaded;
    final loadingPage = page ?? nextPage;
    final updatesEnd = loadingPage == nextPage;
    _emit(Loadable(items, isLoading: true));
    try {
      final result = await onDemand(
        loadingPage,
        itemsPerPage,
        onBuildArguments?.call(loadingPage),
      );

      if (!_isCurrent(requestGeneration)) {
        return result;
      }

      if (result.isNotEmpty) {
        _pages[loadingPage] = result;
      } else {
        _pages.remove(loadingPage);
      }
      if (updatesEnd) {
        _endReached = result.length < itemsPerPage;
      }

      _emit(Loadable(items));
      return result;
    } catch (ex, stack) {
      if (_isCurrent(requestGeneration)) {
        _emit(Loadable(items, error: ex, stack: stack));
      }
      rethrow;
    }
  }

  /// Disposes internal stream controller.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _generation++;
    _isDisposed = true;
    _lce = Loadable.idle();
    _streamController.close();
  }

  bool _isCurrent(int requestGeneration) => !_isDisposed && requestGeneration == _generation;

  void _emit(Loadable<List<T>> loadable) {
    _lce = loadable;
    if (!_streamController.isClosed) {
      _streamController.add(loadable);
    }
  }
}
