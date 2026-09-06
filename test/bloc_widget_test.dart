import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provided bloc survives dependency updates and provider replacement', (tester) async {
    final first = _TestBloc('first');
    final second = _TestBloc('second');
    final hostKey = GlobalKey<_ProviderHostState>();
    const probeKey = Key('probe');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _ProviderHost(
          key: hostKey,
          initialBloc: first,
          child: const _Probe(key: probeKey),
        ),
      ),
    );

    final state = tester.state<_ProbeState>(find.byKey(probeKey));
    expect(state.bloc, same(first));
    expect(state.previous, same(first.state));
    expect(first.initEvents, 0);

    hostKey.currentState!.replace(second);
    await tester.pump();

    expect(state.bloc, same(second));
    expect(state.previous, same(second.state));
    expect(second.initEvents, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provided bloc does not complete blocCreated twice after an inherited update', (tester) async {
    final bloc = _TestBloc('provided');
    const probeKey = Key('probe');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider<_TestBloc>.value(
          value: bloc,
          child: const _Probe(key: probeKey, watchDirectionality: true),
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<_TestBloc>.value(
          value: bloc,
          child: const _Probe(key: probeKey, watchDirectionality: true),
        ),
      ),
    );

    final state = tester.state<_ProbeState>(find.byKey(probeKey));
    expect(state.bloc, same(bloc));
    expect(tester.takeException(), isNull);
  });

  testWidgets('created bloc receives OnInit exactly once', (tester) async {
    final bloc = _TestBloc('created');
    const probeKey = Key('probe');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Probe(key: probeKey, createBloc: (_) => bloc),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: _Probe(key: probeKey, createBloc: (_) => bloc),
      ),
    );
    await tester.pump();

    final state = tester.state<_ProbeState>(find.byKey(probeKey));
    expect(state.bloc, same(bloc));
    expect(state.previous, same(bloc.state));
    expect(bloc.initEvents, 1);
  });

  testWidgets('created narrow-event bloc safely skips the incompatible legacy OnInit event', (tester) async {
    final bloc = _NarrowEventBloc('created');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _NarrowProbe(createBloc: (_) => bloc),
      ),
    );
    await tester.pump();

    expect(bloc.initializationEvents, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('created narrow-event bloc receives its overridden initialization event', (tester) async {
    final bloc = _NarrowEventBloc('created');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _TypedNarrowProbe(createBloc: (_) => bloc),
      ),
    );
    await tester.pump();

    expect(bloc.initializationEvents, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not swallow an unrelated provided-bloc override error', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Probe(provideBloc: (_) => throw StateError('unrelated provider failure')),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('does not swallow an external provider creation error', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider<_TestBloc>(
          create: (_) => throw StateError('provider failure'),
          child: const _Probe(),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(exception.toString(), contains('provider failure'));
  });

  testWidgets('does not treat a missing provider dependency as a missing bloc', (tester) async {
    var didCreateFallback = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider<_TestBloc>(
          create: (context) {
            context.watch<_MissingDependency>();
            return _TestBloc('unreachable');
          },
          child: _Probe(
            createBloc: (_) {
              didCreateFallback = true;
              return _TestBloc('fallback');
            },
          ),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(exception.toString(), contains('_MissingDependency'));
    expect(didCreateFallback, isFalse);
  });

  testWidgets('does not suppress a TypeError thrown by a compatible legacy OnInit bloc', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _FaultyEventProbe(createBloc: (_) => _FaultyEventBloc()),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(exception.toString(), contains('not a subtype of type'));
  });

  testWidgets('propagates created-bloc initialization failures', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Probe(createBloc: (_) => throw StateError('creation failure')),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });
}

class _TestState implements BlocState {
  const _TestState(this.name);

  final String name;
}

class _TestBloc extends Bloc<BlocEvent, _TestState> {
  _TestBloc(this.name) : super(_TestState(name)) {
    on<OnInit>((event, emit) {});
  }

  final String name;
  var initEvents = 0;

  @override
  void onEvent(BlocEvent event) {
    if (event is OnInit) {
      initEvents++;
    }
    super.onEvent(event);
  }
}

sealed class _FeatureEvent implements BlocEvent {}

final class _FeatureInitialization extends _FeatureEvent {}

class _NarrowEventBloc extends Bloc<_FeatureEvent, _TestState> {
  _NarrowEventBloc(this.name) : super(_TestState(name)) {
    on<_FeatureInitialization>((event, emit) {});
  }

  final String name;
  var initializationEvents = 0;

  @override
  void onEvent(_FeatureEvent event) {
    if (event is _FeatureInitialization) {
      initializationEvents++;
    }
    super.onEvent(event);
  }
}

class _FaultyEventBloc extends Bloc<BlocEvent, _TestState> {
  _FaultyEventBloc() : super(const _TestState('faulty')) {
    on<OnInit>((event, emit) {});
  }

  @override
  void onEvent(BlocEvent event) {
    super.onEvent(event);
    if (event is OnInit) {
      final Object value = 1;
      value as String;
    }
  }
}

class _MissingDependency {}

class _Probe extends BlocWidget<_TestState, _TestBloc> {
  const _Probe({super.key, this.createBloc, this.provideBloc, this.watchDirectionality = false});

  final _TestBloc? Function(BuildContext context)? createBloc;
  final _TestBloc? Function(BuildContext context)? provideBloc;
  final bool watchDirectionality;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends BlocWidgetState<_TestState, _TestBloc, _Probe> {
  @override
  _TestBloc? onCreateBloc(BuildContext context) => widget.createBloc?.call(context);

  @override
  _TestBloc? onProvideBloc(BuildContext context) {
    if (widget.watchDirectionality) {
      Directionality.of(context);
    }
    return widget.provideBloc?.call(context) ?? super.onProvideBloc(context);
  }

  @override
  Widget buildContent(BuildContext context, _TestState state) => Text(bloc.name, textDirection: TextDirection.ltr);
}

class _NarrowProbe extends BlocWidget<_TestState, _NarrowEventBloc> {
  const _NarrowProbe({this.createBloc});

  final _NarrowEventBloc? Function(BuildContext context)? createBloc;

  @override
  State<_NarrowProbe> createState() => _NarrowProbeState();
}

class _NarrowProbeState extends BlocWidgetState<_TestState, _NarrowEventBloc, _NarrowProbe> {
  @override
  _NarrowEventBloc? onCreateBloc(BuildContext context) => widget.createBloc?.call(context);

  @override
  Widget buildContent(BuildContext context, _TestState state) => Text(bloc.name, textDirection: TextDirection.ltr);
}

class _TypedNarrowProbe extends BlocWidget<_TestState, _NarrowEventBloc> {
  const _TypedNarrowProbe({this.createBloc});

  final _NarrowEventBloc? Function(BuildContext context)? createBloc;

  @override
  State<_TypedNarrowProbe> createState() => _TypedNarrowProbeState();
}

class _TypedNarrowProbeState extends BlocWidgetState<_TestState, _NarrowEventBloc, _TypedNarrowProbe> {
  @override
  _NarrowEventBloc? onCreateBloc(BuildContext context) => widget.createBloc?.call(context);

  @override
  BlocEvent onInitializationEvent(BuildContext context) => _FeatureInitialization();

  @override
  Widget buildContent(BuildContext context, _TestState state) => Text(bloc.name, textDirection: TextDirection.ltr);
}

class _FaultyEventProbe extends BlocWidget<_TestState, _FaultyEventBloc> {
  const _FaultyEventProbe({this.createBloc});

  final _FaultyEventBloc? Function(BuildContext context)? createBloc;

  @override
  State<_FaultyEventProbe> createState() => _FaultyEventProbeState();
}

class _FaultyEventProbeState extends BlocWidgetState<_TestState, _FaultyEventBloc, _FaultyEventProbe> {
  @override
  _FaultyEventBloc? onCreateBloc(BuildContext context) => widget.createBloc?.call(context);

  @override
  Widget buildContent(BuildContext context, _TestState state) => const SizedBox();
}

class _ProviderHost extends StatefulWidget {
  const _ProviderHost({super.key, required this.initialBloc, required this.child});

  final _TestBloc initialBloc;
  final Widget child;

  @override
  State<_ProviderHost> createState() => _ProviderHostState();
}

class _ProviderHostState extends State<_ProviderHost> {
  late _TestBloc _bloc = widget.initialBloc;

  void replace(_TestBloc bloc) => setState(() => _bloc = bloc);

  @override
  Widget build(BuildContext context) => BlocProvider<_TestBloc>.value(value: _bloc, child: widget.child);
}
