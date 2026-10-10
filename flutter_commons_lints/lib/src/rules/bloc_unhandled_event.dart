import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// Every concrete subclass of a sealed Bloc event type needs an `on<...>`
/// registration in the Bloc.
///
/// A sealed class keeps all its subclasses in its own library, so the set of
/// events is known statically. Adding an event without a handler makes Bloc
/// throw in debug builds and drop the event in release builds.
class BlocUnhandledEvent extends AnalysisRule {
  static const LintCode code = LintCode(
    'bloc_unhandled_event',
    "The Bloc '{0}' doesn't register a handler for: {1}.",
    correctionMessage: 'Try registering an on<Event> handler for each listed event.',
    severity: DiagnosticSeverity.WARNING,
  );

  BlocUnhandledEvent() : super(name: 'bloc_unhandled_event', description: 'Every event of a sealed Bloc event type must have a handler.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

/// Concrete events of the sealed event type of [node] that no `on<...>`
/// registration covers; empty when [node] is not a direct sealed-event Bloc.
List<ClassElement> unhandledEvents(ClassDeclaration node, TypeSystem typeSystem) {
  final element = node.declaredFragment?.element;
  final supertype = element?.supertype;
  if (element == null || element.isAbstract || supertype == null || !supertype.isBloc) {
    return const [];
  }
  final eventType = supertype.typeArguments.first;
  if (eventType is! InterfaceType) {
    return const [];
  }
  final eventElement = eventType.element;
  if (eventElement is! ClassElement || !eventElement.isSealed) {
    return const [];
  }
  final handled = node.eventRegistrations.map((it) => it.eventType).nonNulls.toList();
  return [
    for (final candidate in eventElement.library.classes)
      if (!candidate.isAbstract &&
          !candidate.isSealed &&
          typeSystem.isSubtypeOf(candidate.thisType, eventType) &&
          !handled.any((type) => typeSystem.isSubtypeOf(candidate.thisType, type)))
        candidate,
  ];
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final missing = unhandledEvents(node, context.typeSystem);
    if (missing.isEmpty) {
      return;
    }
    final name = node.namePart.typeName;
    rule.reportAtOffset(name.offset, name.length, arguments: [name.lexeme, missing.map((it) => it.displayName).join(', ')]);
  }
}
