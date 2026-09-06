import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Public abstract class BlocWidget.
abstract class BlocWidget<S extends BlocState, B extends Bloc<BlocEvent, S>> extends StatefulWidget {
  const BlocWidget({super.key});
}

/// Public abstract class BlocWidgetState.
abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W extends BlocWidget<S, B>> extends State<W> with MountedCheck {
  Widget buildContent(BuildContext context, S state);

  @protected
  void onReactions(BuildContext context, S previous, S state) {}

  @protected
  bool containsReactions(S previous, S state) => true;

  @protected
  @mustCallSuper
  bool shouldRebuild(S previous, S state) {
    return previous != state;
  }

  B? _providedBloc;
  B? _createdBloc;

  B get bloc => require(_providedBloc ?? _createdBloc);

  S? _previous;

  /// The state preceding the current transition, or the current initial state.
  ///
  /// This is available during the first [buildContent] call and is reset when
  /// an ancestor replaces the provided bloc instance.
  S get previous => _previous ?? state;

  S get state => bloc.state;

  B? onCreateBloc(BuildContext context) => null;

  /// Returns the first event for a created bloc with a narrower event type.
  ///
  /// The legacy default still attempts to add [OnInit] to blocs that accept
  /// [BlocEvent]. Override this hook to return the concrete initial event for
  /// a bloc declared as `Bloc<FeatureEvent, S>`. A returned event is forwarded
  /// as-is, so configuration errors are never suppressed.
  @protected
  BlocEvent? onInitializationEvent(BuildContext context) => null;

  B? onProvideBloc(BuildContext context) => context.watch<B?>();

  final Completer<B> _blocCreated = Completer();

  Future<B> get blocCreated => _blocCreated.future;

  bool get didCreateBloc => _blocCreated.isCompleted;

  void _completeBlocCreated(B bloc) {
    if (!_blocCreated.isCompleted) {
      _blocCreated.complete(bloc);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final providedBloc = onProvideBloc(context);
    if (!identical(_providedBloc, providedBloc)) {
      _previous = providedBloc?.state;
    }
    _providedBloc = providedBloc;
    if (providedBloc != null) {
      _completeBlocCreated(providedBloc);
    }
  }

  Widget _childBuilder(context) => BlocConsumer<B, S>(
    bloc: _providedBloc ?? _createdBloc,
    listener: (context, state) => onReactions(context, previous, state),
    listenWhen: (previous, current) {
      _previous = previous;
      return containsReactions(previous, current);
    },
    buildWhen: (previous, current) {
      _previous = previous;
      return shouldRebuild(previous, current);
    },
    builder: buildContent,
  );

  @override
  Widget build(BuildContext context) {
    return _providedBloc != null
        ? _childBuilder(context)
        : BlocProvider<B>(
            create: (_) {
              final createdBloc = require(onCreateBloc(context));
              _createdBloc = createdBloc;
              _previous = createdBloc.state;
              final args = context.routeArguments;
              final initializationEvent = onInitializationEvent(context);
              if (initializationEvent != null) {
                createdBloc.add(initializationEvent);
              } else {
                _addLegacyInitializationEvent(createdBloc, BlocEvents.init(arguments: args));
              }
              _completeBlocCreated(createdBloc);
              return createdBloc;
            },
            lazy: false,
            child: _childBuilder(context),
          );
  }

  void _addLegacyInitializationEvent(B bloc, OnInit event) {
    try {
      bloc.add(event);
    } on TypeError catch (error, stackTrace) {
      if (!_isIncompatibleLegacyInitializationEvent(error, stackTrace)) {
        rethrow;
      }
    }
  }

  bool _isIncompatibleLegacyInitializationEvent(TypeError error, StackTrace stackTrace) {
    final message = error.toString();
    final firstFrame = stackTrace.toString().split('\n').first;
    return message.contains('OnInit') &&
        message.contains('is not a subtype of type') &&
        message.contains("of 'event'") &&
        firstFrame.contains('Bloc.add');
  }
}
