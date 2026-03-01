import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';

/// Public abstract class BlocWidget.
abstract class BlocWidget<S extends BlocState, B extends Bloc<BlocEvent, S>> extends StatefulWidget {
  const BlocWidget({super.key});
}

/// Public abstract class BlocWidgetState.
abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W extends BlocWidget<S, B>> extends State<W>
    with MountedCheck {
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

  late S _previous;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providedBloc = onProvideBloc(context);
  }

  Widget _childBuilder(context) => BlocConsumer<B, S>(
        bloc: bloc,
        listener: (context, state) => onReactions(context, _previous, state),
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
              _createdBloc = require(onCreateBloc(context));
              final args = context.routeArguments;
              bloc.add(BlocEvents.init(arguments: args));
              return bloc;
            },
            lazy: false,
            child: _childBuilder(context),
          );
  }
}
