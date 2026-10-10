import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// The handler of a `WaitableEvent` must call `complete` or `fail` on it.
///
/// Otherwise `addAndWait` waits until its timeout or the Bloc closes. The
/// check is local to the handler: when the event is passed anywhere else
/// (another method, a field, a closure argument), it is assumed to be
/// completed there. A Bloc with `AutoCloseWaitableEvents` is not reported for
/// events whose result may be empty, since the mixin completes them.
class WaitableEventNotCompleted extends AnalysisRule {
  static const LintCode code = LintCode(
    'waitable_event_not_completed',
    "The handler of '{0}' never completes the event.",
    correctionMessage: "Try calling 'complete' or 'fail' on the event in every path of the handler.",
    severity: DiagnosticSeverity.WARNING,
  );

  WaitableEventNotCompleted() : super(name: 'waitable_event_not_completed', description: 'A WaitableEvent handler must complete or fail the event.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || blocSupertypeOf(element) == null) {
      return;
    }
    final autoCloses = supertypeOf(element, (type) => type.isAutoCloseWaitableEvents) != null;
    for (final registration in node.eventRegistrations) {
      final eventType = registration.eventType;
      final resultType = waitableResultType(eventType);
      if (eventType == null || resultType == null) {
        continue;
      }
      if (autoCloses && allowsEmptyResult(context.typeSystem, resultType)) {
        continue;
      }
      final (parameter, body) = _handlerOf(node, registration.handler);
      if (parameter == null || body == null) {
        continue;
      }
      final usage = _EventUsage(parameter);
      body.accept(usage);
      if (!usage.isCompletedOrEscapes) {
        rule.reportAtNode(registration.invocation, arguments: [eventType.getDisplayString()]);
      }
    }
  }

  /// The event parameter name and body of a handler written as a closure or
  /// as a reference to a method of [node].
  (String?, FunctionBody?) _handlerOf(ClassDeclaration node, Expression? handler) {
    final FormalParameterList? parameters;
    final FunctionBody? body;
    switch (handler) {
      case FunctionExpression():
        parameters = handler.parameters;
        body = handler.body;
      case SimpleIdentifier(:final name) || PropertyAccess(propertyName: SimpleIdentifier(:final name)):
        final method = node.method(name);
        parameters = method?.parameters;
        body = method?.body;
      default:
        return (null, null);
    }
    final first = parameters?.parameters.firstOrNull;
    return (first?.name?.lexeme, body);
  }
}

/// Finds whether a handler body completes the event or lets it escape.
class _EventUsage extends RecursiveAstVisitor<void> {
  _EventUsage(this.parameter);

  final String parameter;
  bool isCompletedOrEscapes = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != parameter || isCompletedOrEscapes) {
      return;
    }
    final parent = node.parent;
    final isMemberAccess = switch (parent) {
      MethodInvocation(:final target) => identical(target, node),
      PrefixedIdentifier(:final prefix) => identical(prefix, node),
      PropertyAccess(:final target) => identical(target, node),
      _ => false,
    };
    if (!isMemberAccess) {
      // Passed, stored or returned: completion happens elsewhere.
      isCompletedOrEscapes = true;
    } else if (parent is MethodInvocation && const {'complete', 'fail'}.contains(parent.methodName.name)) {
      isCompletedOrEscapes = true;
    }
  }
}
