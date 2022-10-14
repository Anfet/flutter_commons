import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

@immutable
class NavigationResult<T> {
  static const resultCancel = -1;
  static const resultSuccess = 0;
  static const resultOther = 1;

  final int result;
  final T? data;

  const NavigationResult(this.result, {this.data});

  factory NavigationResult.success([T? data]) => NavigationResult(resultSuccess, data: data);

  factory NavigationResult.cancel([T? data]) => NavigationResult(resultCancel, data: data);

  factory NavigationResult.other({int result = resultOther, T? data}) => NavigationResult(result, data: data);

  bool get isSuccess => result == resultSuccess;

  bool get isCancelled => result == resultCancel;

  @override
  String toString() {
    return 'NavigationResult{result: $result, data: $data}';
  }

  static NavigationResult<T> of<T>(result) {
    if (result is NavigationResult) return result as NavigationResult<T>;
    if (result == null) return NavigationResult.cancel();
    return NavigationResult.success(result);
  }
}
