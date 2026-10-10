import 'package:flutter_commons_lints/src/rules/waitable_complete_without_result.dart';
import 'package:flutter_commons_lints/src/rules/waitable_event_not_completed.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WaitableCompleteWithoutResultTest);
    defineReflectiveTests(WaitableEventNotCompletedTest);
  });
}

const _events = '''
import 'package:flutter_commons/flutter_commons.dart';

class S implements BlocState {}

sealed class FeatureEvent implements BlocEvent {}

class LoadCount extends FeatureEvent with WaitableEvent<int> {}

class Save extends FeatureEvent with WaitableEvent<void> {}

class Find extends FeatureEvent with WaitableEvent<int?> {}
''';

@reflectiveTest
class WaitableCompleteWithoutResultTest extends FlutterCommonsRuleTest {
  @override
  void setUp() {
    rule = WaitableCompleteWithoutResult();
    super.setUp();
  }

  Future<void> test_non_nullable_result_is_required() async {
    const code = '''${_events}
void handle(LoadCount count, Save save, Find find) {
  count.complete();
  count.complete(1);
  save.complete();
  find.complete();
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('complete();'), 'complete'.length)]);
  }
}

@reflectiveTest
class WaitableEventNotCompletedTest extends FlutterCommonsRuleTest {
  @override
  void setUp() {
    rule = WaitableEventNotCompleted();
    super.setUp();
  }

  Future<void> test_closure_and_method_handlers_without_completion() async {
    const code = '''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<LoadCount>((event, emit) => print(event.hashCode));
    on<Save>(onSave);
  }

  Future<void> onSave(Save event, Emitter<S> emit) async {}
}
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('on<LoadCount>'), 'on<LoadCount>((event, emit) => print(event.hashCode))'.length),
      lint(code.indexOf('on<Save>'), 'on<Save>(onSave)'.length),
    ]);
  }

  Future<void> test_completed_or_escaping_events() async {
    await assertNoDiagnostics('''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<LoadCount>((event, emit) async {
      try {
        event.complete(await Future.value(1));
      } catch (error) {
        event.fail(error);
      }
    });
    on<Save>(onSave);
    on<Find>((event, emit) => _finish(event));
  }

  Future<void> onSave(Save event, Emitter<S> emit) async => event.complete();

  void _finish(Find event) => event.complete(null);
}
''');
  }

  Future<void> test_auto_close_covers_only_empty_results() async {
    const code = '''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> with AutoCloseWaitableEvents<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<LoadCount>((event, emit) {});
    on<Save>((event, emit) {});
    on<Find>((event, emit) {});
  }
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('on<LoadCount>'), 'on<LoadCount>((event, emit) {})'.length)]);
  }
}
