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
