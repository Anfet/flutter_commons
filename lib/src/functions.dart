import 'package:flutter/material.dart';

typedef ValueCallback<T> = void Function(T value);
typedef LateResultValueCallback<F, T> = Future<F> Function(T value);
typedef ResultValueCallback<R, T> = R Function(T value);
typedef ResultRequest<R> = R Function();
typedef LateResultRequest<R> = Future<R> Function();
typedef SortFunc<T> = int Function(T a, T b);
typedef CustomErrorWidgetBuilderFunc<T> = Widget Function(BuildContext context, Object? error);
