import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _Event implements BlocEvent {}

class _WaitableSuccessEvent extends _Event with WaitableEvent<int> {}

class _WaitableFailureEvent extends _Event with WaitableEvent<int> {}

class _WaitableNeverCompletesEvent extends _Event with WaitableEvent<int> {}

class _WaitableCompletesEmptyEvent extends _Event with WaitableEvent<int> {}

class _RegularEvent extends _Event {}

class _ForeignWaitableEvent with WaitableEvent<int> implements BlocEvent {}

class _State implements BlocState {
  final int value;

  const _State(this.value);
}

class _TestBloc extends Bloc<_Event, _State> {
  _TestBloc() : super(const _State(0)) {
    on<_WaitableSuccessEvent>((event, emit) {
      emit(const _State(1));
      event.complete(7);
    });

    on<_WaitableFailureEvent>((event, emit) {
      event.fail(StateError('handler failed'));
    });

    on<_WaitableNeverCompletesEvent>((event, emit) {});

    on<_WaitableCompletesEmptyEvent>((event, emit) => event.complete());

    on<_RegularEvent>((event, emit) {
      emit(const _State(2));
    });
  }
}

class _TrackingBloc extends _TestBloc {
  var activeStreamListeners = 0;
  var cancelledStreamListeners = 0;

  @override
  Stream<_State> get stream => _track(super.stream);

  Stream<_State> _track(Stream<_State> source) {
    return Stream<_State>.multi((controller) {
      activeStreamListeners++;
      final subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () async {
        cancelledStreamListeners++;
        activeStreamListeners--;
        await subscription.cancel();
      };
    }, isBroadcast: true);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('AutoCloseWaitableEvents', () {
    test('closes a wait its handler left pending', () async {
      final bloc = _AutoCloseBloc(StateError('unused'));
      addTearDown(bloc.close);

      await expectLater(bloc.addAndWait(_AutoVoidEvent()), completes);
      await expectLater(
        bloc.addAndWait(_AutoForgottenEvent()),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('_AutoForgottenEvent'))),
      );
      expect(await bloc.addAndWait(_AutoCompletedEvent()), 7);
    });

    test('fails the wait with the error thrown by the handler', () async {
      final failure = StateError('handler threw');
      final uncaught = <Object>[];
      final waitError = Completer<Object>();
      // Bloc rethrows handler errors into the zone the Bloc was created in. An error future does not cross an error
      // zone boundary, so the wait result is captured inside the zone.
      runZonedGuarded(() {
        final bloc = _AutoCloseBloc(failure);
        bloc.addAndWait(_AutoThrowsEvent()).then<void>((_) => waitError.complete('completed'), onError: waitError.complete);
        waitError.future.then((_) => bloc.close());
      }, (error, _) => uncaught.add(error));

      expect(await waitError.future, same(failure));
      expect(uncaught, [same(failure)]);
    });
  });

  group('BlocWaitableEventExt', () {
    test('addAndWait completes with event result', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      final result = await bloc.addAndWait<int>(_WaitableSuccessEvent());
      expect(result, 7);
      expect(bloc.state.value, 1);
    });

    test('addAndWait rejects a waitable event of another Bloc', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      await expectLater(bloc.addAndWait(_ForeignWaitableEvent()), throwsA(isA<IllegalArgumentException>()));
    });

    test('complete without a result for a non-nullable type fails the wait instead of hanging', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      await expectLater(bloc.addAndWait(_WaitableCompletesEmptyEvent()), throwsA(isA<ArgumentError>()));
    });

    test('completes with StaleWaitEventException when the timeout expires', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      await expectLater(
        bloc.addAndWait<int>(
          _WaitableNeverCompletesEvent(),
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(
          isA<StaleWaitEventException>().having(
            (error) => error.message,
            'message',
            contains('timeout'),
          ),
        ),
      );
    });

    test('completes with StaleWaitEventException when bloc closes', () async {
      final bloc = _TestBloc();
      final wait = bloc.addAndWait<int>(_WaitableNeverCompletesEvent());

      await bloc.close();

      await expectLater(
        wait,
        throwsA(
          isA<StaleWaitEventException>().having(
            (error) => error.message,
            'message',
            contains('closed'),
          ),
        ),
      );
    });

    test('completes with StaleWaitEventException when adding to a closed bloc', () async {
      final bloc = _TestBloc();
      await bloc.close();

      await expectLater(
        bloc.addAndWait<int>(_WaitableNeverCompletesEvent()),
        throwsA(isA<StaleWaitEventException>()),
      );
    });

    test('propagates an error explicitly reported by the event handler', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      await expectLater(
        bloc.addAndWait<int>(_WaitableFailureEvent()),
        throwsA(isA<StateError>()),
      );
    });

    test('preserves the original signature without a timeout', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      expect(await bloc.addAndWait<int>(_WaitableSuccessEvent()), 7);
    });

    test('without a timeout, an omitted completion waits until Bloc closes', () async {
      final bloc = _TestBloc();
      final event = _WaitableNeverCompletesEvent();
      final wait = bloc.addAndWait<int>(event);

      await _settle();
      expect(event.completer().isCompleted, isFalse);

      await bloc.close();
      await expectLater(wait, throwsA(isA<StaleWaitEventException>()));
    });

    test('reusing a completed event preserves its completed future', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);
      final event = _WaitableSuccessEvent();

      expect(await bloc.addAndWait<int>(event), 7);
      expect(await bloc.addAndWait<int>(event), 7);
    });

    test('releases the close monitor after success, failure, and timeout', () async {
      final bloc = _TrackingBloc();
      addTearDown(bloc.close);

      expect(await bloc.addAndWait<int>(_WaitableSuccessEvent()), 7);
      await _settle();
      expect(bloc.activeStreamListeners, 0);

      await expectLater(
        bloc.addAndWait<int>(_WaitableFailureEvent()),
        throwsA(isA<StateError>()),
      );
      await _settle();
      expect(bloc.activeStreamListeners, 0);

      await expectLater(
        bloc.addAndWait<int>(
          _WaitableNeverCompletesEvent(),
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<StaleWaitEventException>()),
      );
      await _settle();

      expect(bloc.activeStreamListeners, 0);
      expect(bloc.cancelledStreamListeners, 3);
    });

    test('releases all close monitors after multiple pending waits', () async {
      final bloc = _TrackingBloc();
      final first = bloc.addAndWait<int>(_WaitableNeverCompletesEvent());
      final second = bloc.addAndWait<int>(_WaitableNeverCompletesEvent());

      expect(bloc.activeStreamListeners, 2);
      await bloc.close();

      await expectLater(first, throwsA(isA<StaleWaitEventException>()));
      await expectLater(second, throwsA(isA<StaleWaitEventException>()));
      await _settle();

      expect(bloc.activeStreamListeners, 0);
      expect(bloc.cancelledStreamListeners, 2);
    });
  });
}

sealed class _AutoEvent implements BlocEvent {}

class _AutoThrowsEvent extends _AutoEvent with WaitableEvent<int> {}

class _AutoVoidEvent extends _AutoEvent with WaitableEvent<void> {}

class _AutoForgottenEvent extends _AutoEvent with WaitableEvent<int> {}

class _AutoCompletedEvent extends _AutoEvent with WaitableEvent<int> {}

class _AutoCloseBloc extends Bloc<_AutoEvent, _State> with AutoCloseWaitableEvents<_AutoEvent, _State> {
  _AutoCloseBloc(this.failure) : super(const _State(0)) {
    on<_AutoThrowsEvent>((event, emit) => throw failure);
    on<_AutoVoidEvent>((event, emit) {});
    on<_AutoForgottenEvent>((event, emit) async {});
    on<_AutoCompletedEvent>((event, emit) => event.complete(7));
  }

  final StateError failure;
}
