import 'dart:async';

import 'package:flutter_commons/flutter_commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debounceRestartable drops the result of a handler overtaken by a newer event', () async {
    final responses = {'a': Completer<void>(), 'ab': Completer<void>()};
    final bloc = _SearchBloc(responses);
    addTearDown(bloc.close);
    final emitted = <String>[];
    final subscription = bloc.stream.listen((state) => emitted.add(state.query));
    addTearDown(subscription.cancel);

    bloc.add(const _Search('a'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(const _Search('ab'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    responses['ab']!.complete();
    responses['a']!.complete();
    await Future<void>.delayed(Duration.zero);

    expect(emitted, ['ab']);
  });

  for (final (name, transformer) in [
    ('debounce', debounce<_Waitable>(const Duration(milliseconds: 10))),
    ('debounceRestartable', debounceRestartable<_Waitable>(const Duration(milliseconds: 10))),
    ('throttle', throttle<_Waitable>(const Duration(milliseconds: 50))),
  ]) {
    test('$name fails a dropped waitable event instead of leaving it waiting', () async {
      final bloc = _WaitableBloc(transformer);
      addTearDown(bloc.close);

      final first = bloc.addAndWait(_Waitable(1));
      final second = bloc.addAndWait(_Waitable(2));
      final results = await Future.wait([
        first.then<Object>((value) => value, onError: (Object error) => error),
        second.then<Object>((value) => value, onError: (Object error) => error),
      ]);

      expect(results.whereType<int>(), hasLength(1));
      expect(results.whereType<StaleWaitEventException>(), hasLength(1));
    });
  }
}

class _Search implements BlocEvent {
  const _Search(this.query);

  final String query;

  @override
  String toString() => '_Search{query: $query}';
}

class _SearchState implements BlocState {
  const _SearchState(this.query);

  final String query;
}

class _SearchBloc extends Bloc<_Search, _SearchState> {
  _SearchBloc(Map<String, Completer<void>> responses) : super(const _SearchState('')) {
    on<_Search>((event, emit) async {
      await responses[event.query]!.future;
      emit(_SearchState(event.query));
    }, transformer: debounceRestartable(const Duration(milliseconds: 10)));
  }
}

class _Waitable with WaitableEvent<int> implements BlocEvent {
  _Waitable(this.value);

  final int value;

  @override
  String toString() => '_Waitable{value: $value}';
}

class _WaitableBloc extends Bloc<_Waitable, _SearchState> {
  _WaitableBloc(EventTransformer<_Waitable> transformer) : super(const _SearchState('')) {
    on<_Waitable>((event, emit) => event.complete(event.value), transformer: transformer);
  }
}
