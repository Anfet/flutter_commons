import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// Reports events that cannot implement `WaitableEvent` in `addAndWait`.
class AddAndWaitNonWaitable extends AnalysisRule {
  static const LintCode code = LintCode(
    'add_and_wait_non_waitable',
    "The event passed to 'addAndWait' does not implement 'WaitableEvent'.",
    correctionMessage: "Use 'add' or make the event implement 'WaitableEvent'.",
    severity: DiagnosticSeverity.WARNING,
  );

  AddAndWaitNonWaitable() : super(name: 'add_and_wait_non_waitable', description: 'Events passed to addAndWait must be waitable.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'addAndWait' || node.argumentList.arguments.isEmpty) return;
    final owner = node.methodName.element?.enclosingElement;
    if (owner is! ExtensionElement ||
        owner.name != 'BlocWaitableEventExt' ||
        owner.library.uri.scheme != 'package' ||
        owner.library.uri.pathSegments.first != 'flutter_commons') {
      return;
    }

    final argument = node.argumentList.arguments.first.argumentExpression;
    final type = argument.staticType;
    if (type is! InterfaceType || waitableResultType(type) != null) return;
    if (argument is InstanceCreationExpression && argument.constructorName.element?.isGenerative == true) {
      rule.reportAtNode(argument);
    }
  }
}
