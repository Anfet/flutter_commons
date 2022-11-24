import 'package:flutter/material.dart';

typedef ValueCallback<T> = void Function(T value);
typedef AsyncValueCallback<F, T> = Future<F> Function(T value);
typedef ResultRequest<R> = R Function();
typedef AsyncResultRequest<R> = Future<R> Function();
typedef ResultValueCallback<R, T> = R Function(T value);
typedef AsyncResultValueCallback<R, T> = Future<R> Function(T value);

typedef CustomErrorWidgetBuilderFunc<T> = Widget Function(BuildContext context, Object? error);

typedef WidgetCallback = Widget Function(BuildContext context);
typedef WidgetCallbackWithContent<T> = Widget Function(BuildContext context, T content);
typedef WidgetCallbackWithErrorAndContent<T> = Widget Function(BuildContext context, dynamic error, T content);
