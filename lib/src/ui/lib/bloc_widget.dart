import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

abstract class BlocWidget<S extends BlocState, B extends Bloc<BlocEvent, S>> extends StatefulWidget {
  const BlocWidget({super.key});
}

abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W extends BlocWidget<S, B>> extends State<W>
    with Logging, MountedCheck {
  Widget buildContent(BuildContext context, S state);

  @protected
  void onReactions(BuildContext context) {}

  @protected
  bool containsReactions(S previous, S current) => true;

  @protected
  @mustCallSuper
  bool shouldRebuild(S previous, S current) {
    _previous = previous;
    _state = current;
    return previous != current;
  }

  B? _bloc;

  B get bloc => require(_bloc);

  late S _previous;
  late S _state;

  S get previous => _previous;

  S get state => _state;

  B? onCreateBloc(BuildContext context) => null;

  B? onProvideBloc(BuildContext context) {
    try {
      return BlocProvider.of<B>(context);
    } catch (_) {
      return null;
    }
  }

  Widget _childBuilder(context) => BlocConsumer<B, S>(
        listener: (context, state) => onReactions(context),
        listenWhen: shouldRebuild,
        buildWhen: (previous, current) => shouldRebuild(previous, current),
        builder: buildContent,
      );

  @override
  Widget build(BuildContext context) {
    _bloc = onProvideBloc(context);
    return _bloc == null
        ? BlocProvider<B>(
            create: (_) {
              _bloc = require(onCreateBloc(context));
              final args = context.routeArguments;
              bloc.add(BlocEvents.init(arguments: args));
              return bloc;
            },
            child: _childBuilder(context),
          )
        : _childBuilder(context);
  }
}
