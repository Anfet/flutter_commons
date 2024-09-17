import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

abstract class BlocWidget<S extends BlocState, B extends Bloc<BlocEvent, S>> extends StatefulWidget {
  const BlocWidget({super.key});
}

abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W extends BlocWidget<S, B>> extends State<W>
    with Logging, MountedCheck {
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

  bool? isBlocProvided;
  B? _bloc;

  B get bloc => require(_bloc);

  late S _previous;
  late S _state;

  S get previous => _previous;

  S get state => bloc.state;

  B? onCreateBloc(BuildContext context) => null;

  B? onProvideBloc(BuildContext context) {
    try {
      return BlocProvider.of<B>(context);
    } catch (_) {
      return null;
    }
  }

  Widget _childBuilder(context) =>
      BlocConsumer<B, S>(
        bloc: _bloc,
        listener: (context, state) => onReactions(context, _previous, state),
        listenWhen: (previous, current) {
          _previous = previous;
          _state = current;
          return containsReactions(previous, current);
        },
        buildWhen: (previous, current) {
          _previous = previous;
          _state = current;
          return shouldRebuild(previous, current);
        },
        builder: buildContent,
      );

  @override
  Widget build(BuildContext context) {
    if (isBlocProvided == null) {
      _bloc = onProvideBloc(context);
      isBlocProvided = _bloc != null;
    }


    return require(isBlocProvided) ? _childBuilder(context) : BlocProvider<B>(
      create: (_) {
        _bloc = require(onCreateBloc(context));
        final args = context.routeArguments;
        bloc.add(BlocEvents.init(arguments: args));
        return bloc;
      },
      child: _childBuilder(context),
      lazy: false,
    );
  }
}
