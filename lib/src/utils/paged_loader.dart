import 'package:flutter/cupertino.dart';
import 'package:flutter_commons/flutter_commons.dart';

typedef PagedLoaderCallback<T> = Future<List<T>> Function(int page, int itemsPerPage);

class PagedLoader<T> with Logging {
  final ValueNotifier<List<T>> itemsNotifier = ValueNotifier([]);
  final ValueNotifier<Loadable<List<T>>> lceNotifier = ValueNotifier(const Loadable([]));

  final int itemsPerPage;
  final int initialPage;
  final PagedLoaderCallback<T> onDemand;

  int get page => _page;

  bool get endReached => _endReached;

  bool get isLoading => lceNotifier.value.isLoading;

  List<T> get items => _pages.values.fold([], (previousValue, element) => previousValue + element);

  int _page = 0;
  bool _endReached = false;
  final Map<int, List<T>> _pages = {};

  void clear() {
    trace('clearing paged loader');
    _pages.clear();
    _page = initialPage - 1;
    _endReached = false;
    itemsNotifier.value = [];
    lceNotifier.value = itemsNotifier.value.asLoadable;
  }

  Future<(List<T> items, bool endReached)> loadNextPage() async {
    if (_endReached || isLoading) {
      trace('load next page denied; already loading');
      return (<T>[], _endReached);
    }

    lceNotifier.value = Loadable(items, isLoading: true);
    try {
      var loadingPage = _page + 1;
      trace("loading page '$loadingPage'");
      var result = await onDemand(loadingPage, itemsPerPage);
      _endReached = result.isEmpty || result.length < itemsPerPage;
      if (result.isNotEmpty) {
        _page = loadingPage;
        _pages.putIfAbsent(_page, () => result);
      }

      lceNotifier.value = Loadable(items, isLoading: false);
      trace("items returned '${result.length}'; end reached = ${_endReached ? 'true' : 'false'}");
      return (result, _endReached);
    } catch (ex, stack) {
      warn("page '${_page + 1}' load error", error: ex, stack: stack);
      lceNotifier.value = Loadable(items, isLoading: false, error: ex, stack: stack);
    }

    return (<T>[], _endReached);
  }

  PagedLoader({
    required this.itemsPerPage,
    required this.onDemand,
    this.initialPage = 0,
  });
}
