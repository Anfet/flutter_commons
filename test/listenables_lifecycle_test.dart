import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stream completion', () {
    for (final values in <List<int>>[
      [],
      [1, 2],
    ]) {
      test('finite stream $values finishes once without explicit cancellation', () async {
        final mapped = <int>[];
        var completions = 0;
        final errors = <Object>[];
        final cancellable = StreamCancellable<int>(
          Stream<int>.fromIterable(values),
          (value) => mapped.add(value),
          onCancel: () => completions++,
          onError: (error, _) => errors.add(error),
        );

        await _settle();

        expect(mapped, values);
        expect(cancellable.isCancelled, isTrue);
        expect(completions, 1);
        expect(errors, isEmpty);
        await cancellable.cancelAndWait();
        cancellable.cancel();
        expect(completions, 1);
      });
    }

    test('natural completion waits for the last mapper', () async {
      final gate = Completer<void>();
      var completions = 0;
      final cancellable = StreamCancellable<int>(
        Stream<int>.value(1),
        (_) => gate.future,
        onCancel: () => completions++,
      );

      await _settle();
      expect(completions, 0);
      gate.complete();
      await _settle();

      expect(completions, 1);
      await cancellable.cancelAndWait();
      expect(completions, 1);
    });

    test('explicit cancellation racing pending completion finishes once', () async {
      final gate = Completer<void>();
      final mapped = <int>[];
      var completions = 0;
      var sourceCleanups = 0;
      final controller = StreamController<int>(onCancel: () => sourceCleanups++);
      final cancellable = StreamCancellable<int>(
        controller.stream,
        (value) async {
          mapped.add(value);
          await gate.future;
        },
        onCancel: () => completions++,
      );
      controller.add(1);
      controller.add(2);
      final sourceClosed = controller.close();
      await _settle();
      expect(mapped, [1]);

      await cancellable.cancelAndWait();
      gate.complete();
      await sourceClosed;
      await _settle();

      expect(mapped, [1]);
      expect(completions, 1);
      expect(sourceCleanups, 1);
      expect(controller.hasListener, isFalse);
    });

    test('throwing completion callback reports once and remains finished', () async {
      final failure = StateError('completion failed');
      final reports = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      var completions = 0;
      final cancellable = StreamCancellable<int>(
        const Stream<int>.empty(),
        (_) => true,
        onCancel: () {
          completions++;
          throw failure;
        },
      );

      await _settle();
      await cancellable.cancelAndWait();

      expect(cancellable.isCancelled, isTrue);
      expect(completions, 1);
      expect(reports.single.exception, same(failure));
    });
  });

  group('Owner registration lifecycle', () {
    test('BlocListenables removes naturally completed and cancelled registrations', () async {
      final bloc = _ListenableBloc();
      final controller = StreamController<int>();
      addTearDown(bloc.close);
      addTearDown(controller.close);
      bloc.onStreamChange<int>(Stream<int>.value(1), (_) => true);
      final active = bloc.onStreamChange<int>(controller.stream, (_) => true);
      expect(bloc.debugActiveListenableCount, 2);

      await _settle();
      expect(bloc.debugActiveListenableCount, 1);
      active.cancel();
      expect(bloc.debugActiveListenableCount, 0);
      await active.cancelAndWait();
    });

    test('BlocListenables cancels reentrant, closing and closed registrations', () async {
      final bloc = _ListenableBloc();
      final gate = Completer<void>();
      final notifier = _TrackingNotifier();
      final value = _TrackingValueNotifier<int>(0);
      final registrations = <Cancellable>[];
      final controllers = <StreamController<int>>[];
      var calls = 0;
      void register() {
        final controller = StreamController<int>();
        controllers.add(controller);
        registrations.addAll([
          bloc.onStreamChange<int>(controller.stream, (_) => calls++),
          bloc.onAnyChange(notifier, () => calls++),
          bloc.onValueChanged<int>(value, (_) => calls++),
        ]);
        controller.add(1);
        notifier.notifyListeners();
        value.value++;
        expect(controller.hasListener, isFalse);
        expect(notifier.hasActiveListeners, isFalse);
        expect(value.hasActiveListeners, isFalse);
        expect(bloc.debugActiveListenableCount, 0);
      }

      final first = StreamController<int>(
        onCancel: () {
          register();
          return gate.future;
        },
      );
      addTearDown(notifier.dispose);
      addTearDown(value.dispose);
      bloc.onStreamChange<int>(first.stream, (_) => calls++);

      var closed = false;
      final closing = bloc.close().then((_) => closed = true);
      expect(controllers, hasLength(1));
      register();
      await _settle();
      expect(closed, isFalse);
      expect(bloc.isClosed, isFalse);
      expect(calls, 0);

      gate.complete();
      await closing;
      expect(bloc.isClosed, isTrue);
      register();
      await Future.wait(registrations.map((registration) => registration.cancelAndWait()));
      await first.close();
      await Future.wait(controllers.map((controller) => controller.close()));
      expect(calls, 0);
      expect(bloc.debugActiveListenableCount, 0);
    });

    testWidgets('StateListenable removes naturally completed and cancelled registrations', (tester) async {
      final key = GlobalKey<_RegistrationHostState>();
      await tester.pumpWidget(_RegistrationHost(key: key));
      final state = key.currentState!;
      await tester.runAsync(() async {
        final controller = StreamController<int>();
        state.onStreamChange<int>(Stream<int>.value(1), (_) => true);
        final active = state.onStreamChange<int>(controller.stream, (_) => true);
        expect(state.debugActiveListenableCount, 2);

        await _settle();
        expect(state.debugActiveListenableCount, 1);
        active.cancel();
        expect(state.debugActiveListenableCount, 0);
        await active.cancelAndWait();
        await controller.close();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      expect(state.debugActiveListenableCount, 0);
    });

    testWidgets('StateListenable cancels registrations during and after disposal', (tester) async {
      final key = GlobalKey<_RegistrationHostState>();
      await tester.pumpWidget(_RegistrationHost(key: key));
      final state = key.currentState!;
      final notifier = _TrackingNotifier();
      final value = _TrackingValueNotifier<int>(0);
      final registrations = <Cancellable>[];
      final controllers = <StreamController<int>>[];
      var calls = 0;
      void register() {
        final controller = StreamController<int>();
        controllers.add(controller);
        registrations.addAll([
          state.onStreamChange<int>(controller.stream, (_) => calls++),
          state.onAnyChange(notifier, () => calls++),
          state.onValueChanged<int>(value, (_) => calls++),
        ]);
        controller.add(1);
        notifier.notifyListeners();
        value.value++;
        expect(controller.hasListener, isFalse);
        expect(notifier.hasActiveListeners, isFalse);
        expect(value.hasActiveListeners, isFalse);
        expect(state.debugActiveListenableCount, 0);
      }

      addTearDown(notifier.dispose);
      addTearDown(value.dispose);
      final first = await tester.runAsync(() async {
        final controller = StreamController<int>(onCancel: register);
        state.onStreamChange<int>(controller.stream, (_) => calls++);
        return controller;
      });

      await tester.pumpWidget(const SizedBox.shrink());
      expect(state.mounted, isFalse);
      expect(controllers, hasLength(1));
      await tester.runAsync(() async {
        register();
        await Future.wait(registrations.map((registration) => registration.cancelAndWait()));
        await first!.close();
        await Future.wait(controllers.map((controller) => controller.close()));
      });

      expect(calls, 0);
      expect(state.debugActiveListenableCount, 0);
    });
  });

  group('Cancellation failures', () {
    test('throwing onCancel still detaches a value listener exactly once', () async {
      final notifier = _TrackingValueNotifier<int>(0);
      final failure = StateError('onCancel failed');
      final stack = StackTrace.fromString('original onCancel stack');
      var calls = 0;
      final cancellable = ListenableCancellable<int>(
        notifier,
        (_) => true,
        onCancel: () {
          calls++;
          Error.throwWithStackTrace(failure, stack);
        },
      );
      addTearDown(notifier.dispose);

      try {
        cancellable.cancel();
        fail('Expected onCancel to throw');
      } catch (error, actualStack) {
        expect(error, same(failure));
        expect(actualStack.toString(), stack.toString());
      }
      await cancellable.cancelAndWait();

      expect(notifier.hasActiveListeners, isFalse);
      expect(calls, 1);
    });

    test('throwing onCancel still detaches a notifier listener', () async {
      final notifier = _TrackingNotifier();
      final failure = StateError('onCancel failed');
      final cancellable = NotifierCancellable(notifier, () => true, onCancel: () => throw failure);
      addTearDown(notifier.dispose);

      expect(cancellable.cancel, throwsA(same(failure)));
      await cancellable.cancelAndWait();

      expect(notifier.hasActiveListeners, isFalse);
    });

    test('cancelAndWait waits for resources even when onCancel throws', () async {
      final gate = Completer<void>();
      final failure = StateError('onCancel failed');
      final stack = StackTrace.fromString('original stream cancellation stack');
      var cleanupCalls = 0;
      final controller = StreamController<int>(
        onCancel: () {
          cleanupCalls++;
          return gate.future;
        },
      );
      final cancellable = StreamCancellable<int>(
        controller.stream,
        (_) => true,
        onCancel: () {
          Error.throwWithStackTrace(failure, stack);
        },
      );
      addTearDown(controller.close);
      var finished = false;
      final completion = Future<void>.sync(cancellable.cancelAndWait).then<void>(
        (_) {
          fail('Expected cancellation failure');
        },
        onError: (Object error, StackTrace actualStack) {
          finished = true;
          expect(error, same(failure));
          expect(actualStack.toString(), stack.toString());
        },
      );

      await _settle();
      expect(cleanupCalls, 1);
      expect(finished, isFalse);
      gate.complete();
      await completion;
      await cancellable.cancelAndWait();
      expect(cleanupCalls, 1);
    });

    test('void cancel reports asynchronous resource errors with their stack', () async {
      final failure = StateError('resource cleanup failed');
      final stack = StackTrace.fromString('resource cleanup stack');
      final reports = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      final controller = StreamController<int>(onCancel: () => Future<void>.error(failure, stack));
      final cancellable = StreamCancellable<int>(controller.stream, (_) => true);
      addTearDown(controller.close);

      cancellable.cancel();
      cancellable.cancel();
      await _settle();

      expect(reports, hasLength(1));
      expect(reports.single.exception, same(failure));
      expect(reports.single.stack.toString(), stack.toString());
      await expectLater(cancellable.cancelAndWait(), throwsA(same(failure)));
    });

    test('cancelAndWait preserves onCancel error and reports a simultaneous cleanup error', () async {
      final failure = StateError('onCancel failed');
      final stack = StackTrace.fromString('onCancel stack');
      final cleanupFailure = StateError('cleanup failed');
      final cleanupStack = StackTrace.fromString('cleanup stack');
      final reports = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      final controller = StreamController<int>(onCancel: () => Error.throwWithStackTrace(cleanupFailure, cleanupStack));
      final cancellable = StreamCancellable<int>(
        controller.stream,
        (_) => true,
        onCancel: () {
          Error.throwWithStackTrace(failure, stack);
        },
      );
      addTearDown(controller.close);

      try {
        await cancellable.cancelAndWait();
        fail('Expected onCancel to throw');
      } catch (error, actualStack) {
        expect(error, same(failure));
        expect(actualStack.toString(), stack.toString());
      }

      expect(controller.hasListener, isFalse);
      expect(reports, hasLength(1));
      expect(reports.single.exception, same(cleanupFailure));
      expect(reports.single.stack.toString(), cleanupStack.toString());
    });

    test('mapper self-cancellation reports onCancel errors and detaches its listener', () async {
      final notifier = _TrackingNotifier();
      final failure = StateError('onCancel failed');
      final stack = StackTrace.fromString('self-cancellation stack');
      final reports = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      addTearDown(notifier.dispose);
      final cancellable = NotifierCancellable(
        notifier,
        () => false,
        onCancel: () {
          Error.throwWithStackTrace(failure, stack);
        },
      );

      await _settle();
      await cancellable.cancelAndWait();

      expect(notifier.hasActiveListeners, isFalse);
      expect(reports, hasLength(1));
      expect(reports.single.exception, same(failure));
      expect(reports.single.stack.toString(), stack.toString());
    });

    test('BlocListenables closes after attempting every failing registration', () async {
      final failure = StateError('first cleanup failed');
      final stack = StackTrace.fromString('first cleanup stack');
      final otherFailure = StateError('second cleanup failed');
      final otherStack = StackTrace.fromString('second cleanup stack');
      final reports = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      var cleanupCalls = 0;
      final first = StreamController<int>(
        onCancel: () {
          cleanupCalls++;
          return Future<void>.error(failure, stack);
        },
      );
      final second = StreamController<int>(
        onCancel: () {
          cleanupCalls++;
          return Future<void>.error(otherFailure, otherStack);
        },
      );
      final notifier = _TrackingNotifier();
      final bloc = _ListenableBloc();
      addTearDown(first.close);
      addTearDown(second.close);
      addTearDown(notifier.dispose);
      bloc.onStreamChange<int>(first.stream, (_) => true);
      bloc.onStreamChange<int>(second.stream, (_) => true);
      bloc.onAnyChange(notifier, () => true);

      final closing = bloc.close();
      final repeatedClosing = bloc.close();
      final repeatedAssertion = expectLater(repeatedClosing, throwsA(same(failure)));
      try {
        await closing;
        fail('Expected cleanup failure');
      } catch (error, actualStack) {
        expect(error, same(failure));
        expect(actualStack.toString(), stack.toString());
      }
      await repeatedAssertion;

      expect(bloc.isClosed, isTrue);
      expect(notifier.hasActiveListeners, isFalse);
      expect(cleanupCalls, 2);
      expect(reports, hasLength(1));
      expect(reports.single.exception, same(otherFailure));
      expect(reports.single.stack.toString(), otherStack.toString());
    });
  });

  group('ListenableCancellable lifecycle', () {
    test('cancelling drops notifications queued behind an in-flight mapper', () async {
      final notifier = _TrackingValueNotifier<int>(0);
      final gate = Completer<void>();
      final started = <int>[];
      final cancellable = ListenableCancellable<int>(notifier, (value) async {
        started.add(value);
        if (value == 0) {
          await gate.future;
        }
        return true;
      });
      addTearDown(notifier.dispose);

      await _settle();
      expect(started, [0]);

      notifier.value = 1;
      cancellable.cancel();
      cancellable.cancel();
      gate.complete();
      await _settle();

      expect(started, [0]);
      expect(notifier.hasActiveListeners, isFalse);
    });

    test('NotifierCancellable drops notifications queued behind an in-flight mapper', () async {
      final notifier = _TrackingNotifier();
      final gate = Completer<void>();
      var started = 0;
      final cancellable = NotifierCancellable(notifier, () async {
        started++;
        if (started == 1) {
          await gate.future;
        }
        return true;
      });
      addTearDown(notifier.dispose);

      await _settle();
      expect(started, 1);

      notifier.notifyListeners();
      cancellable.cancel();
      gate.complete();
      await _settle();

      expect(started, 1);
      expect(notifier.hasActiveListeners, isFalse);
    });

    test('self-cancellation drops notifications already queued by the notifier', () async {
      final notifier = _TrackingValueNotifier<int>(0);
      final started = <int>[];
      final cancellable = ListenableCancellable<int>(notifier, (value) {
        started.add(value);
        return false;
      });
      addTearDown(notifier.dispose);

      notifier.value = 1;
      notifier.value = 2;
      await _settle();

      expect(started, [0]);
      cancellable.cancel();
      expect(notifier.hasActiveListeners, isFalse);
    });
  });

  test('StreamCancellable reports source and mapper errors to its handler', () async {
    final controller = StreamController<int>();
    final errors = <Object>[];
    final cancellable = StreamCancellable<int>(
      controller.stream,
      (_) => throw StateError('mapper failure'),
      onError: (error, _) => errors.add(error),
    );
    addTearDown(controller.close);

    controller.add(1);
    controller.addError(ArgumentError('source failure'));
    await _settle();
    await cancellable.cancelAndWait();

    expect(errors.whereType<StateError>().single.toString(), contains('mapper failure'));
    expect(errors.whereType<ArgumentError>().single.toString(), contains('source failure'));
  });

  testWidgets('StateListenable cancels queued mapper work during dispose', (tester) async {
    final notifier = _TrackingValueNotifier<int>(0);
    final gate = Completer<void>();
    final started = <int>[];
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _StateHost(notifier: notifier, gate: gate, started: started),
      ),
    );
    await tester.pump();
    expect(started, [0]);

    notifier.value = 1;
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(started, [0]);
    expect(notifier.hasActiveListeners, isFalse);
  });

  test('BlocListenables cancels queued mapper work before close completes', () async {
    final notifier = _TrackingValueNotifier<int>(0);
    final gate = Completer<void>();
    final started = <int>[];
    final bloc = _ListenableBloc();
    addTearDown(notifier.dispose);
    addTearDown(bloc.close);

    bloc.onValueChanged<int>(notifier, (value) async {
      started.add(value);
      if (value == 0) {
        await gate.future;
      }
      return true;
    });
    await _settle();
    expect(started, [0]);

    notifier.value = 1;
    await bloc.close();
    gate.complete();
    await _settle();

    expect(started, [0]);
    expect(notifier.hasActiveListeners, isFalse);
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _RegistrationHost extends StatefulWidget {
  const _RegistrationHost({super.key});

  @override
  State<_RegistrationHost> createState() => _RegistrationHostState();
}

class _RegistrationHostState extends State<_RegistrationHost> with StateListenable<_RegistrationHost> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _StateHost extends StatefulWidget {
  const _StateHost({required this.notifier, required this.gate, required this.started});

  final ValueNotifier<int> notifier;
  final Completer<void> gate;
  final List<int> started;

  @override
  State<_StateHost> createState() => _StateHostState();
}

class _StateHostState extends State<_StateHost> with StateListenable<_StateHost> {
  @override
  void initState() {
    super.initState();
    onValueChanged<int>(widget.notifier, (value) async {
      widget.started.add(value);
      if (value == 0) {
        await widget.gate.future;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Event implements BlocEvent {}

class _BlocState implements BlocState {
  const _BlocState();
}

class _ListenableBloc extends Bloc<_Event, _BlocState> with BlocListenables<_Event, _BlocState> {
  _ListenableBloc() : super(const _BlocState());
}

class _TrackingNotifier extends ChangeNotifier {
  bool get hasActiveListeners => hasListeners;
}

class _TrackingValueNotifier<T> extends ValueNotifier<T> {
  _TrackingValueNotifier(super.value);

  bool get hasActiveListeners => hasListeners;
}
