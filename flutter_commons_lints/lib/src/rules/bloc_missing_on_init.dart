import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// A Bloc that accepts `OnInit` must register `on<OnInit>`.
///
/// `BlocWidgetState` adds `OnInit` to every Bloc it creates. Without the
/// registration Bloc throws in debug builds and silently drops the event in
/// release builds.
class BlocMissingOnInit extends AnalysisRule {
  static const LintCode code = LintCode(
    'bloc_missing_on_init',
    "The Bloc '{0}' accepts OnInit but doesn't register 'on<OnInit>'.",
    correctionMessage: "Try registering 'on<OnInit>(onInit)' in the constructor.",
    severity: DiagnosticSeverity.WARNING,
  );

  BlocMissingOnInit() : super(name: 'bloc_missing_on_init', description: 'A Bloc with BlocEvent events must register on<OnInit>.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

/// Whether [node] is a concrete direct `Bloc` subclass that must register
/// `on<OnInit>` but doesn't.
bool isMissingOnInit(ClassDeclaration node) {
  final element = node.declaredFragment?.element;
  final supertype = element?.supertype;
  if (element == null || element.isAbstract || supertype == null || !supertype.isBloc) {
    return false;
  }
  if (!acceptsOnInit(supertype.typeArguments.first)) {
    return false;
  }
  return !node.eventRegistrations.any((registration) {
    final type = registration.eventType;
    return type is InterfaceType && type.isOnInit;
  });
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (isMissingOnInit(node)) {
      final name = node.namePart.typeName;
      rule.reportAtOffset(name.offset, name.length, arguments: [name.lexeme]);
    }
  }
}
