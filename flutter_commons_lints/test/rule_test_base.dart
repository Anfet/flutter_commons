import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart' show ExpectedDiagnostic; // ignore: implementation_imports
import 'package:test/test.dart';

/// Rule test with minimal `bloc` and `flutter_commons` stubs.
///
/// The stubs mirror only the declarations the rules inspect: names, type
/// parameters and members that are looked up.
abstract class FlutterCommonsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('bloc').addFile('lib/bloc.dart', r'''
import 'dart:async';

abstract class Emitter<S> {
  void call(S state);
}

abstract class Bloc<E, S> {
  Bloc(S initialState);

  void on<T extends E>(FutureOr<void> Function(T event, Emitter<S> emit) handler, {Object? transformer}) {}
}
''');
    newPackage('flutter_commons').addFile('lib/flutter_commons.dart', r'''
import 'package:bloc/bloc.dart';

export 'package:bloc/bloc.dart';

abstract interface class BlocEvent {}

abstract interface class BlocState {}

class OnInit implements BlocEvent {}

mixin WaitableEvent<T> {
  void complete([T? result]) {}

  void fail(Object error) {}
}

mixin AutoCloseWaitableEvents<E, S> on Bloc<E, S> {}

extension BlocWaitableEventExt<E extends BlocEvent, S> on Bloc<E, S> {
  Future<T> addAndWait<T>(E event) async => throw UnimplementedError();
}

abstract class BlocWidgetState<S extends BlocState, B extends Bloc<BlocEvent, S>, W> {
  B? onCreateBloc() => null;

  BlocEvent? onInitializationEvent() => null;
}
''');
    super.setUp();
  }

  /// Asserts that [code] reports exactly [diagnostic], applies [producer] at
  /// it and compares the fixed code with [expected].
  Future<void> assertFix(
    String code,
    ExpectedDiagnostic diagnostic,
    ResolvedCorrectionProducer Function(CorrectionProducerContext context) producer,
    String expected,
  ) async {
    await assertDiagnostics(code, [diagnostic]);
    final reported = result.diagnostics.single;
    final library = await result.session.getResolvedLibrary(result.path) as ResolvedLibraryResult;
    final context = CorrectionProducerContext.createResolved(
      libraryResult: library,
      unitResult: result,
      diagnostic: reported,
      selectionOffset: reported.offset,
      selectionLength: reported.length,
    );
    final builder = ChangeBuilder(session: result.session, defaultEol: '\n');
    await producer(context).compute(builder);
    final edits = builder.sourceChange.edits.single.edits;
    expect(SourceEdit.applySequence(code, edits), expected);
  }
}
