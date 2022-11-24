import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_core/src/navigation/navigation_arguments.dart';

typedef ReactionHandler<S extends BlocState, V> = FutureOr<dynamic> Function(BuildContext context, S state, V value);
typedef ReactionGetter<T> = BlocReaction<T> Function();

abstract class BlocWidget<S extends BlocState, B extends BlocEx<S>> extends StatefulWidget {
  const BlocWidget({Key? key}) : super(key: key);
}

abstract class BlocWidgetState<S extends BlocState, B extends BlocEx<S>, W extends BlocWidget<S, B>> extends State<W> {
  final Map<ReactionGetter<dynamic>, ReactionHandler<S, dynamic>> _reactions = {};

  B? _bloc;

  // B get bloc => _bloc!;

  B onCreateBloc(BuildContext context);

  Widget buildContent(BuildContext context, S state);

  @protected
  void onReactions(BuildContext context, S state) {
    for (final pair in _reactions.entries) {
      final reaction = pair.key();
      if (reaction.isConsumed) {
        continue;
      }

      reaction.consume((value) => pair.value.call(context, state, value));
    }
  }

  @protected
  bool containsReactions(S previous, S current) =>
      _reactions.keys.map((getter) => getter()).any((reaction) => !reaction.isConsumed);

  @protected
  bool shouldRebuild(S previous, S current) => previous != current;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null) {
      _bloc = onCreateBloc(context);
      final args = context.routeArguments;
      assert(args == null || args is! NavigationArguments, 'route arguments not NavigationData');
      _bloc?.push(BlocEvents.init(arguments: args));
    }
  }

  @override
  void dispose() {
    Future.sync(() => _bloc?.close());
    super.dispose();
  }

  List<Provider> otherProviders() => [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>.value(
      value: _bloc ?? throwWtf(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => BlocConsumer<B, S>(
          listener: (context, state) => onReactions(context, state),
          listenWhen: (previous, current) => containsReactions(previous, current),
          builder: (context, state) => MultiProvider(
            providers: [
              Provider<BoxConstraints>(create: (context) => constraints),
              Provider<Orientation>(
                create: (context) =>
                    constraints.maxWidth > constraints.maxHeight ? Orientation.landscape : Orientation.portrait,
              ),
              ...otherProviders(),
            ],
            builder: (context, child) => buildContent(context, state),
          ),
          buildWhen: (previous, current) => shouldRebuild(previous, current),
        ),
      ),
    );
  }

  void run(BlocEvent event) => _bloc?.push(event);

  Future<X> runAndAwait<X>(BlocEvent event) => _bloc?.pushAndAwait<X>(event) ?? throwWtf();

  void on<T>(ReactionGetter<T> getter, ReactionHandler<S, T> handler) {
    _reactions[getter] = handler as ReactionHandler<S, dynamic>;
  }
}
