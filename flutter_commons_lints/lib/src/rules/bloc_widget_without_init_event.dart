import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// A `BlocWidgetState` that creates a Bloc whose events cannot accept `OnInit`
/// must override `onInitializationEvent`.
///
/// Otherwise the legacy `OnInit` is rejected by the Bloc's event type and
/// `BlocWidgetState` swallows the rejection, so the Bloc never starts.
class BlocWidgetWithoutInitEvent extends AnalysisRule {
  static const LintCode code = LintCode(
    'bloc_widget_without_init_event',
    "'{0}' creates a '{1}', which can't accept OnInit, but doesn't override 'onInitializationEvent'.",
    correctionMessage: "Try overriding 'onInitializationEvent' to return the Bloc's initial event.",
    severity: DiagnosticSeverity.WARNING,
  );

  BlocWidgetWithoutInitEvent()
    : super(name: 'bloc_widget_without_init_event', description: 'A BlocWidgetState creating a narrowly typed Bloc must provide its initial event.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || element.isAbstract) {
      return;
    }
    final widgetState = supertypeOf(element, (type) => type.isBlocWidgetState);
    final bloc = widgetState?.typeArguments[1];
    if (widgetState == null || bloc is! InterfaceType) {
      return;
    }
    final blocSupertype = blocSupertypeOf(bloc.element);
    final eventType = blocSupertype == null ? null : bloc.asInstanceOf(blocSupertype.element)?.typeArguments.first;
    if (eventType == null || eventType is TypeParameterType || acceptsOnInit(eventType)) {
      return;
    }
    if (!_overrides(element, 'onCreateBloc') || _overrides(element, 'onInitializationEvent')) {
      return;
    }
    final name = node.namePart.typeName;
    rule.reportAtOffset(name.offset, name.length, arguments: [name.lexeme, bloc.element.displayName]);
  }

  bool _overrides(ClassElement element, String method) {
    return [
      element.thisType,
      ...element.allSupertypes,
    ].where((type) => !type.isBlocWidgetState).any((type) => type.element.methods.any((it) => it.name == method));
  }
}
