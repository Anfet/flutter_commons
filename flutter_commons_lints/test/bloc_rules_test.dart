import 'package:flutter_commons_lints/src/fixes/add_event_handlers.dart';
import 'package:flutter_commons_lints/src/rules/bloc_missing_on_init.dart';
import 'package:flutter_commons_lints/src/rules/bloc_unhandled_event.dart';
import 'package:flutter_commons_lints/src/rules/bloc_widget_without_init_event.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rule_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlocMissingOnInitTest);
    defineReflectiveTests(BlocWidgetWithoutInitEventTest);
    defineReflectiveTests(BlocUnhandledEventTest);
  });
}

const _header = '''
import 'package:flutter_commons/flutter_commons.dart';

class S implements BlocState {}
''';

@reflectiveTest
class BlocMissingOnInitTest extends FlutterCommonsRuleTest {
  @override
  void setUp() {
    rule = BlocMissingOnInit();
    super.setUp();
  }

  Future<void> test_missing_registration() async {
    const code = '''${_header}
class FeatureBloc extends Bloc<BlocEvent, S> {
  FeatureBloc() : super(S());
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('FeatureBloc'), 'FeatureBloc'.length)]);
  }

  Future<void> test_registered_or_not_applicable() async {
    await assertNoDiagnostics('''${_header}
sealed class FeatureEvent implements BlocEvent {}

class Registered extends Bloc<BlocEvent, S> {
  Registered() : super(S()) {
    on<OnInit>((event, emit) {});
  }
}

class NarrowEvents extends Bloc<FeatureEvent, S> {
  NarrowEvents() : super(S());
}

abstract class BaseBloc extends Bloc<BlocEvent, S> {
  BaseBloc() : super(S());
}
''');
  }

  Future<void> test_fix_adds_registration_and_handler() async {
    const code = '''${_header}
class FeatureBloc extends Bloc<BlocEvent, S> {
  FeatureBloc() : super(S());
}
''';
    await assertFix(code, lint(code.indexOf('FeatureBloc'), 'FeatureBloc'.length), (context) => AddOnInitHandler(context: context), '''${_header}
class FeatureBloc extends Bloc<BlocEvent, S> {
  FeatureBloc() : super(S()) {
    on<OnInit>(onInit);
  }

  Future<void> onInit(OnInit event, Emitter<S> emit) async {}
}
''');
  }
}

@reflectiveTest
class BlocWidgetWithoutInitEventTest extends FlutterCommonsRuleTest {
  @override
  void setUp() {
    rule = BlocWidgetWithoutInitEvent();
    super.setUp();
  }

  static const _blocs = '''${_header}
sealed class FeatureEvent implements BlocEvent {}

class NarrowBloc extends Bloc<FeatureEvent, S> {
  NarrowBloc() : super(S());
}

class WideBloc extends Bloc<BlocEvent, S> {
  WideBloc() : super(S());
}
''';

  Future<void> test_created_narrow_bloc_without_initial_event() async {
    const code = '''${_blocs}
class Screen extends BlocWidgetState<S, NarrowBloc, Object> {
  @override
  NarrowBloc? onCreateBloc() => NarrowBloc();
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('Screen'), 'Screen'.length)]);
  }

  Future<void> test_initial_event_provided_or_not_needed() async {
    await assertNoDiagnostics('''${_blocs}
class WithEvent extends BlocWidgetState<S, NarrowBloc, Object> {
  @override
  NarrowBloc? onCreateBloc() => NarrowBloc();

  @override
  BlocEvent? onInitializationEvent() => null;
}

class Provided extends BlocWidgetState<S, NarrowBloc, Object> {}

class Wide extends BlocWidgetState<S, WideBloc, Object> {
  @override
  WideBloc? onCreateBloc() => WideBloc();
}
''');
  }
}

@reflectiveTest
class BlocUnhandledEventTest extends FlutterCommonsRuleTest {
  @override
  void setUp() {
    rule = BlocUnhandledEvent();
    super.setUp();
  }

  static const _events = '''${_header}
sealed class FeatureEvent implements BlocEvent {}

class Load extends FeatureEvent {}

sealed class Edit extends FeatureEvent {}

class Rename extends Edit {}

class Delete extends Edit {}
''';

  Future<void> test_lists_every_unhandled_event() async {
    const code = '''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<Rename>((event, emit) {});
  }
}
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('FeatureBloc'), 'FeatureBloc'.length, messageContainsAll: ['Load', 'Delete']),
    ]);
  }

  Future<void> test_handled_through_a_sealed_parent() async {
    await assertNoDiagnostics('''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<Load>((event, emit) {});
    on<Edit>((event, emit) {});
  }
}
''');
  }

  Future<void> test_fix_adds_handlers_for_missing_events() async {
    const code = '''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<Edit>(onEdit);
  }

  Future<void> onEdit(Edit event, Emitter<S> emit) async {}
}
''';
    await assertFix(
      code,
      lint(code.indexOf('FeatureBloc'), 'FeatureBloc'.length),
      (context) => AddUnhandledEventHandlers(context: context),
      '''${_events}
class FeatureBloc extends Bloc<FeatureEvent, S> {
  FeatureBloc() : super(S()) {
    on<Edit>(onEdit);
    on<Load>(onLoad);
  }

  Future<void> onLoad(Load event, Emitter<S> emit) async {}

  Future<void> onEdit(Edit event, Emitter<S> emit) async {}
}
''',
    );
  }
}
