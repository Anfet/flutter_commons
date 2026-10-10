import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../bloc_model.dart';
import '../rules/bloc_missing_on_init.dart';
import '../rules/bloc_unhandled_event.dart';

/// Registers `on<OnInit>(onInit)` and adds an empty `onInit` handler.
class AddOnInitHandler extends _AddEventHandlers {
  static const _kind = FixKind('flutter_commons.fix.addOnInitHandler', DartFixKindPriority.standard, "Register 'on<OnInit>(onInit)'");

  AddOnInitHandler({required super.context});

  @override
  FixKind get fixKind => _kind;

  @override
  List<String> eventNames(ClassDeclaration declaration) => isMissingOnInit(declaration) ? const ['OnInit'] : const [];
}

/// Registers an `on<Event>` handler with an empty body for every unhandled event.
class AddUnhandledEventHandlers extends _AddEventHandlers {
  static const _kind = FixKind(
    'flutter_commons.fix.addUnhandledEventHandlers',
    DartFixKindPriority.standard,
    'Register handlers for the unhandled events',
  );

  AddUnhandledEventHandlers({required super.context});

  @override
  FixKind get fixKind => _kind;

  @override
  List<String> eventNames(ClassDeclaration declaration) => [for (final event in unhandledEvents(declaration, typeSystem)) event.displayName];
}

/// Inserts `on<Event>(onEvent);` into the first constructor and an empty
/// handler method right after it.
abstract class _AddEventHandlers extends ResolvedCorrectionProducer {
  _AddEventHandlers({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  List<String> eventNames(ClassDeclaration declaration);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) {
      return;
    }
    final names = eventNames(declaration);
    final constructor = declaration.constructors.firstOrNull;
    final stateType = declaration.declaredFragment?.element.supertype?.typeArguments.last;
    if (names.isEmpty || constructor == null || stateType == null) {
      return;
    }

    final eol = utils.endOfLine;
    final indent = utils.getNodePrefix(constructor);
    final inner = '$indent${utils.oneIndent}';
    final registrations = [for (final name in names) '${inner}on<$name>(${_handlerName(name)});'].join(eol);
    final state = stateType.getDisplayString();
    final handlers = [
      for (final name in names) '$eol$eol${indent}Future<void> ${_handlerName(name)}($name event, Emitter<$state> emit) async {}',
    ].join();

    await builder.addDartFileEdit(file, (builder) {
      switch (constructor.body) {
        case BlockFunctionBody(:final block) when block.statements.isNotEmpty:
          builder.addSimpleInsertion(block.statements.last.end, '$eol$registrations');
        case BlockFunctionBody(:final block):
          builder.addSimpleInsertion(block.leftBracket.end, '$eol$registrations$eol$indent');
        case EmptyFunctionBody(:final semicolon):
          builder.addSimpleReplacement(SourceRange(semicolon.offset, semicolon.length), ' {$eol$registrations$eol$indent}');
        default:
          return;
      }
      builder.addSimpleInsertion(constructor.end, handlers);
    });
  }

  String _handlerName(String event) {
    if (event == 'OnInit') {
      return 'onInit';
    }
    final isPrivate = event.startsWith('_');
    final name = event.replaceFirst(RegExp('^_+'), '');
    return '${isPrivate ? '_' : ''}on$name';
  }
}
