import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_core/src/navigation/navigation_arguments.dart';

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
  final CustomNavigator navigator;
  final Map<Type, CancelableOperation> delayedEvents = {};

  BlocEx(
    S initialState, {
    required this.navigator,
  }) {
    _bloc = _BlocInternal(
      initialState,
      onEventReceived: (event) => logMessage("\t> $event"),
      onErrorThrown: (error, stackTrace) =>
          logMessage("\t> $error", level: Level.error, error: error, stackTrace: stackTrace),
      onBlocClose: _dispose,
    );

    on<OnInit>(onInit);
    on<UpdateState>((event, emit) => emit(event.newState as S));
    on<OnChainResult>(onChainResult);
  }

  void debounced<E extends BlocEvent>(EventHandlerEx<E, S> handler, {EventTransformer<E>? transformer}) => _bloc.on<E>(
        (event, emit) {
          CancelableOperation? delayedEvent = delayedEvents[E.runtimeType];
          delayedEvent?.cancel();
          var delayed = CancelableOperation.fromFuture(Future.delayed(const Duration(milliseconds: 300)));
          delayedEvents[E.runtimeType] = delayed;
          delayed.then((_) => handler(event, emit)).then(
                (result) => _eventAwaiters.remove(event.eventId)?.complete(result),
                onError: (error, stackTrace) => _eventAwaiters
                    .remove(event.eventId)
                    ?.completeError(error ?? WtfException("Error without an error"), stackTrace),
              );
        },
        transformer: transformer,
      );

  void on<E extends BlocEvent>(EventHandlerEx<E, S> handler, {EventTransformer<E>? transformer}) => _bloc.on<E>(
        (event, emit) {
          return Future.value(handler(event, emit))
              .then(
                (result) => _eventAwaiters.remove(event.eventId)?.complete(result),
              )
              .onError(
                (error, stackTrace) => _eventAwaiters
                    .remove(event.eventId)
                    ?.completeError(error ?? WtfException("Error without an error"), stackTrace),
              );
        },
        transformer: transformer,
      );

  @protected
  @mustCallSuper
  FutureOr<void> onInit(OnInit event, Emitter<S> emit) {
    event.arguments?.use((it) => _onNavigationArgumentsPresent(it));
  }

  void _onNavigationArgumentsPresent(final NavigationArguments arguments) {
    final path = arguments.navigationPath;
    if (path == null) {
      return;
    }

    NavigationChain chain = NavigationChain(path);
    NavigationChainFlow flow = processNavigationChain(arguments);
    logMessage("received $chain in navigation args; decision = $flow");
    switch (flow) {
      case NavigationChainFlow.push:
        navigator
            .pushNamed(chain.path, data: arguments)
            .then((result) => push(BlocEvents.onChainResult(result, arguments)));
        break;
      case NavigationChainFlow.replace:
        navigator.replaceNamed(chain.path, data: arguments);
        break;
      case NavigationChainFlow.ignore:
        break;
    }
  }

  NavigationChainFlow processNavigationChain(final NavigationArguments arguments) => NavigationChainFlow.push;

  FutureOr onChainResult(OnChainResult event, Emitter<S> emit) => null;

  Future<void> _dispose() async {
    logMessage("\t> disposing");
    _eventAwaiters.clear();
    await _subscriptions.close();
  }

  void push(BlocEvent event) {
    if (_bloc.isDisposed) {
      logCustom("$runtimeType is disposed; cannot push ${event.runtimeType}", level: Level.verbose);
      return;
    }
    _bloc.add(event);
  }

  Future<X> pushAndAwait<X>(BlocEvent event) {
    if (_bloc.isDisposed) {
      logCustom("$runtimeType is disposed; cannot push ${event.runtimeType}", level: Level.verbose);
      return Future<X>. error(FlowException("$runtimeType is disposed"));
    }

    final completer = Completer<X>();
    _eventAwaiters[event.eventId] = completer;
    push(event);
    return completer.future;
  }

  void subscribeTo<T>(Stream<T> stream, FutureOr<dynamic> Function(T value) listener) =>
      _subscriptions.subscribeTo(stream, listener);

  @override
  Future<void> close() => _bloc.close();

  @override
  bool get isClosed => _bloc.isClosed;

  @override
  S get state => _bloc.state;

  @override
  Stream<S> get stream => _bloc.stream;
}
