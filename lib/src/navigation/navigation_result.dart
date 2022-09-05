import 'package:flutter/widgets.dart';

@immutable
class NavigationResult {
  static const resultCancel = -1;
  static const resultSuccess = 0;
  static const resultOther = 1;

  final int result;
  final dynamic data;

  const NavigationResult(this.result, {this.data});

  factory NavigationResult.success({dynamic data}) => NavigationResult(resultSuccess, data: data);

  factory NavigationResult.cancel({dynamic data}) => NavigationResult(resultCancel, data: data);

  factory NavigationResult.other({int result = resultOther, dynamic data}) => NavigationResult(result, data: data);

  bool get isSuccess => result == resultSuccess;

  bool get isCancelled => result == resultCancel;

  @override
  String toString() {
    return 'NavigationResult{result: $result, data: $data}';
  }

  static NavigationResult ofAny(result) {
    if (result == null) return NavigationResult.cancel();
    if (result is NavigationResult) return result;
    return NavigationResult.success(data: result);
  }
}
