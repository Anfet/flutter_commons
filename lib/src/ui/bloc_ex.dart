import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:siberian_core/siberian_core.dart';

import '../data/composite_subscription.dart';
import '../functions.dart';
import '../logger.dart';
import 'bloc_events.dart';
import 'bloc_state.dart';

typedef EventHandlerEx<Event, State> = FutureOr<dynamic> Function(
  Event event,
  Emitter<State> emit,
);

class _BlocInternal<S extends BlocState> extends Bloc<BlocEvent, S> {
  bool isDisposed = false;

  final ValueCallback<BlocEvent>? onEventReceived;
  final Function(Object error, StackTrace stackTrace)? onErrorThrown;
  final Future Function()? onBlocClose;

  _BlocInternal(
    super.initialState, {
    this.onEventReceived,
    this.onErrorThrown,
    this.onBlocClose,
  });

  @override
  @protected
  @mustCallSuper
  void onEvent(BlocEvent event) {
    onEventReceived?.call(event);
    super.onEvent(event);
  }

  @override
  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    onErrorThrown?.call(error, stackTrace);
    super.onError(error, stackTrace);
  }

  @override
  @mustCallSuper
  Future<void> close() async {
    if (onBlocClose != null) {
      await onBlocClose?.call();
    }

    isDisposed = true;

    return super.close();
  }
}

class BlocEx<S extends BlocState> extends StateStreamableSource<S> with Logging {
  late final _BlocInternal<S> _bloc;

  final Map<int, Completer> _eventAwaiters = {};
  final CompositeSubscription _subscriptions = CompositeSubscription();

  BlocEx(S initialState) {
    _bloc = _BlocInternal(
      initialState,
      onEventReceived: (event) => logMessage("\t> $event"),
      onErrorThrown: (error, stackTrace) =>
          logMessage("\t> $error", level: Level.error, error: error, stackTrace: stackTrace),
      onBlocClose: _dispose,
    );

    on<OnInit>(onInit);
    on<UpdateState>((event, emit) => emit(event.newState as S));
  }

  void on<E extends BlocEvent>(EventHandlerEx<E, S> handler, {EventTransformer<E>? transformer}) => _bloc.on<E>(
      (event, emit) => Future.value(handler(event, emit))
          .then(
            (result) => _eventAwaiters.remove(event.eventId)?.complete(result),
          )
          .onError(
            (error, stackTrace) => _eventAwaiters
                .remove(event.eventId)
                ?.completeError(error ?? WtfException("Error without an error"), stackTrace),
          ),
      transformer: transformer);

  @protected
  FutureOr<void> onInit(OnInit event, Emitter<S> emit) {}

  @protected
  Future<void> _dispose() async {
    logMessage("\t> disposing");
    _eventAwaiters.clear();
    await _subscriptions.close();
  }

  void push(BlocEvent event) {
    if (_bloc.isDisposed) {
      throw FlowException("$runtimeType is disposed");
    }
    _bloc.add(event);
  }

  Future<X> pushAndAwait<X>(BlocEvent event) {
    if (_bloc.isDisposed) {
      return Future<X>.error(FlowException("$runtimeType is disposed"));
    }

    final completer = Completer<X>();
    _eventAwaiters[event.eventId] = completer;
    push(event);
    return completer.future;
  }

  void subscribeTo<T>(Stream<T> stream, FutureOr<dynamic> Function(T value) listener) =>
      _subscriptions.subscribeTo(stream, listener);

  @override
  FutureOr<void> close() => _bloc.close();

  @override
  bool get isClosed => _bloc.isClosed;

  @override
  S get state => _bloc.state;

  @override
  Stream<S> get stream => _bloc.stream;
}
