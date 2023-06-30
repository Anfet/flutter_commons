import 'package:flutter/cupertino.dart';
import 'package:siberian_core/siberian_core.dart';

typedef PagedLoaderCallback<T> = Future<List<T>> Function(int page, int itemsPerPage);

class PagedLoader<T> with Logging {
  final ValueNotifier<List<T>> itemsNotifier = ValueNotifier([]);
  final ValueNotifier<Lce<List<T>>> lceNotifier = ValueNotifier(const Lce.content([]));

  final int itemsPerPage;
  final int initialPage;
  final PagedLoaderCallback<T> onDemand;

  int get page => _page;

  bool get endReached => _endReached;

  bool get isLoading => lceNotifier.value.isLoading;

  List<T> get items => _pages.values.fold([], (previousValue, element) => previousValue + element);

  int _page = 0;
  bool _endReached = false;
  Map<int, List<T>> _pages = {};

  void clear() {
    verbose('clearing paged loader');
    _pages.clear();
    _page = initialPage - 1;
    _endReached = false;
    itemsNotifier.value = [];
    lceNotifier.value = itemsNotifier.value.asContent;
  }

  Future<(List<T> items, bool endReached)> loadNextPage() async {
    if (_endReached || isLoading) {
      verbose('load next page denied; already loading');
      return (<T>[], _endReached);
    }

    lceNotifier.value = Lce(isLoading: true, content: items);
    try {
      var loadingPage = _page + 1;
      verbose("loading page '$loadingPage'");
      var result = await onDemand(loadingPage, itemsPerPage);
      _endReached = result.isEmpty || result.length < itemsPerPage;
      if (result.isNotEmpty) {
        _page = loadingPage;
        _pages.putIfAbsent(_page, () => result);
      }

      lceNotifier.value = Lce(isLoading: false, content: items);
      verbose("items returned '${result.length}'; end reached = ${_endReached ? 'true' : 'false'}");
      return (result, _endReached);
    } catch (ex, stack) {
      warn("page '${_page + 1}' load error", error: ex, stackTrace: stack);
      lceNotifier.value = Lce(isLoading: false, content: items, error: ex, stack: stack);
    }

    return (<T>[], _endReached);
  }

  PagedLoader({
    required this.itemsPerPage,
    required this.onDemand,
    this.initialPage = 0,
  });
}
