import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:siberian_core/siberian_core.dart';

import '../extensions/context_ext.dart';
import 'bloc_events.dart';
import 'bloc_ex.dart';
import 'bloc_state.dart';

abstract class BlocWidget<S extends BlocState, B extends BlocEx<S>> extends StatefulWidget {
  const BlocWidget({Key? key}) : super(key: key);
}

abstract class BlocWidgetState<S extends BlocState, B extends BlocEx<S>, W extends BlocWidget<S, B>> extends State<W> {
  B? _bloc;

  B get bloc => _bloc!;

  B onCreateBloc(BuildContext context);

  Widget buildContent(BuildContext context, S state);

  @protected
  void onEvent(BuildContext context, S state) {}

  @protected
  bool containsEvent(S previous, S current) =>
      current.reactions.filter((it) => it != null).cast<BlocReaction>().any((it) => !it.isConsumed);

  @protected
  bool shouldRebuild(S previous, S current) => previous != current;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null) {
      _bloc = onCreateBloc(context);
      _bloc?.push(BlocEvents.init(arguments: context.routeArguments));
    }
  }

  @override
  void dispose() {
    Future.sync(() => bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>.value(
      value: bloc,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => BlocConsumer<B, S>(
          listener: (context, state) => onEvent(context, state),
          listenWhen: (previous, current) => containsEvent(previous, current),
          builder: (context, state) => MultiProvider(
            providers: [
              Provider<BoxConstraints>(create: (context) => constraints),
              Provider<Orientation>(
                create: (context) =>
                    constraints.maxWidth > constraints.maxHeight ? Orientation.landscape : Orientation.portrait,
              ),
            ],
            builder: (context, child) => buildContent(context, state),
          ),
          buildWhen: (previous, current) => shouldRebuild(previous, current),
        ),
      ),
    );
  }

  void run(BlocEvent event) => bloc.push(event);

  Future<X> runAndAwait<X>(BlocEvent event) => bloc.pushAndAwait<X>(event);
}
