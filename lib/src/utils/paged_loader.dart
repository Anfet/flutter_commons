import 'dart:async';
import 'dart:collection';

import 'package:flutter_commons/flutter_commons.dart';

typedef PagedLoaderCallback<T, A> = Future<List<T>> Function(int page, int itemsPerPage, [A? arguments]);

/// Loads paged data on demand and keeps accumulated items in memory.
///
/// Exposes [stream] with loading/content/error state updates.
class PagedLoader<T, A> {
  final StreamController<Loadable<List<T>>> _streamController = StreamController.broadcast();
  Stream<Loadable<List<T>>> get stream => _streamController.stream;

  Loadable<List<T>> _lce = Loadable.idle();

  final int itemsPerPage;
  final int initialPage;
  final PagedLoaderCallback<T, A> onDemand;
  final TypedResultCallback<A, int>? onBuildArguments;

  final SplayTreeMap<int, Loadable<List<T>>> _pages = SplayTreeMap<int, Loadable<List<T>>>();

  int get lastPageLoaded => _pages.keys.last;
  int get nextPageToBeLoaded => (_pages.keys.lastOrNull ?? (initialPage - 1)) + 1;

  bool get didLoadAnything => _pages.isNotEmpty;

  bool get didReachEnd => _endReached;

  bool get isLoading => _lce.isLoading;
  bool get hasError => _lce.hasError;

  List<T> get items => _pages.values.fold([], (previousValue, element) => previousValue + element.requireValue);

  bool _endReached = false;

  PagedLoader({
    required this.itemsPerPage,
    required this.onDemand,
    this.onBuildArguments,
    this.initialPage = 0,
  });

  /// Clears loaded pages and resets pagination state to the initial page.
  void clear() {
    _pages.clear();
    _endReached = false;

    _emit(Loadable.idle());
  }

  /// Loads the next page unless loading is already in progress or the end is reached.
  ///
  /// Returns loaded page items.
  Future<List<T>> loadPage({int? page}) async {
    if (_endReached || isLoading) {
      return [];
    }

    var loadingPage = page ?? nextPageToBeLoaded;
    _emit(_lce.loading().clearError());
    try {
      var result = await onDemand(
        loadingPage,
        itemsPerPage,
        onBuildArguments?.call(loadingPage),
      );
      _endReached = result.isEmpty || result.length < itemsPerPage;
      if (result.isNotEmpty) {
        _pages.putIfAbsent(loadingPage, () => result.asLoadable);
      }

      _emit(_lce.result(items));
      return result;
    } catch (ex, stack) {
      _pages.putIfAbsent(loadingPage, () => Loadable.error(ex, stack));
      _emit(_lce.fail(ex, stack));
      rethrow;
    } finally {
      _emit(_lce.idle());
    }
  }

  /// Disposes internal stream controller.
  void dispose() {
    _streamController.close();
  }

  void _emit(Loadable<List<T>> loadable) {
    _lce = loadable;
    if (!_streamController.isClosed) {
      _streamController.add(loadable);
    }
  }
}
