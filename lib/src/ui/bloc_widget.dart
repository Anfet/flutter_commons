import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siberian_core/siberian_core.dart';
import 'package:siberian_logger/siberian_logger.dart';

abstract class BlocWidget<S extends BlocState, B extends Bloc<BlocEvent, S>> extends StatefulWidget {
  const BlocWidget({super.key});
}

abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W extends BlocWidget<S, B>> extends State<W>
    with Logging, MountedStateMixin {
  late B bloc;

  B onCreateBloc(BuildContext context);

  Widget buildContent(BuildContext context, S state);

  @protected
  void onReactions(BuildContext context, S state) {}

  @protected
  bool containsReactions(S previous, S current) => true;

  @protected
  bool shouldRebuild(S previous, S current) => previous != current;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>(
      create: (_) {
        bloc = onCreateBloc(context);
        final args = context.routeArguments;
        bloc.add(BlocEvents.init(arguments: args));
        return bloc;
      },
      child: BlocConsumer<B, S>(
        listener: onReactions,
        listenWhen: containsReactions,
        buildWhen: (previous, current) => shouldRebuild(previous, current),
        builder: buildContent,
      ),
    );
  }
}
