import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef TypedCallback<T> = ValueSetter<T>;
typedef TypedCallbackP2<P1, P2> = void Function(P1 param1, P2 param2);
typedef TypedCallbackP3<P1, P2, P3> = void Function(P1 param1, P2 param2, P3 param3);

typedef AsyncTypedCallback<F, T> = Future<F> Function(T value);
typedef TypedResult<R> = ValueGetter<R>;
typedef TypedResultR2<R1, R2> = (R1, R2) Function();

typedef AsyncTypedResult<R> = AsyncValueGetter<R>;
typedef TypedResultCallback<R, T> = R Function(T value);
typedef AsyncTypedResultCallback<R, T> = Future<R> Function(T value);

typedef CustomErrorWidgetBuilderFunc<T> = Widget Function(BuildContext context, Object? error);

typedef WidgetCallback = Widget Function(BuildContext context);
typedef WidgetCallbackExtended<T> = Widget Function(BuildContext context, {Object? error, T? content});
