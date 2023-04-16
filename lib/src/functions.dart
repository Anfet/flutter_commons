import 'package:flutter/material.dart';

typedef TypedCallback<T> = void Function(T value);
typedef AsyncTypedCallback<F, T> = Future<F> Function(T value);
typedef TypedResult<R> = R Function();
typedef AsyncTypedResult<R> = Future<R> Function();
typedef TypedResultCallback<R, T> = R Function(T value);
typedef AsyncTypedResultCallback<R, T> = Future<R> Function(T value);

typedef CustomErrorWidgetBuilderFunc<T> = Widget Function(BuildContext context, Object? error);

typedef WidgetCallback = Widget Function(BuildContext context);
typedef WidgetCallbackExtended<T> = Widget Function(BuildContext context, {Object? error, T? content});
