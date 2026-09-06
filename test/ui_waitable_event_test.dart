import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _Event implements BlocEvent {}

class _WaitableSuccessEvent extends _Event with WaitableEvent<int> {}

class _WaitableFailureEvent extends _Event with WaitableEvent<int> {}

class _WaitableNeverCompletesEvent extends _Event with WaitableEvent<int> {}

class _RegularEvent extends _Event {}

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
  group('BlocWaitableEventExt', () {
    test('addAndWait completes with event result', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      final result = await bloc.addAndWait<int>(_WaitableSuccessEvent());
      expect(result, 7);
      expect(bloc.state.value, 1);
    });

    test('addAndWait throws when event is not WaitableEvent<T>', () async {
      final bloc = _TestBloc();
      addTearDown(bloc.close);

      expect(
        () => bloc.addAndWait<int>(_RegularEvent()),
        throwsA(isA<IllegalArgumentException>()),
      );
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
