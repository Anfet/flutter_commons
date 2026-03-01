import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _Event implements BlocEvent {}

class _WaitableSuccessEvent extends _Event with WaitableEvent<int> {}

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

    on<_RegularEvent>((event, emit) {
      emit(const _State(2));
    });
  }
}

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
  });
}
