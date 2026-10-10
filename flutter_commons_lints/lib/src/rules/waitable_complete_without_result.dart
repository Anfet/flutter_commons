import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../bloc_model.dart';

/// `complete()` without a result on a `WaitableEvent<T>` with a non-nullable
/// `T` fails the wait at runtime with an `ArgumentError`.
class WaitableCompleteWithoutResult extends AnalysisRule {
  static const LintCode code = LintCode(
    'waitable_complete_without_result',
    "'complete()' needs a result of type '{0}'.",
    correctionMessage: 'Try passing the result, or make the result type nullable or void.',
    severity: DiagnosticSeverity.WARNING,
  );

  WaitableCompleteWithoutResult()
    : super(name: 'waitable_complete_without_result', description: 'A WaitableEvent with a non-nullable result must be completed with a value.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'complete' || node.argumentList.arguments.isNotEmpty) {
      return;
    }
    final target = node.realTarget;
    final targetType = target == null ? node.thisOrAncestorOfType<ClassDeclaration>()?.declaredFragment?.element.thisType : target.staticType;
    final resultType = waitableResultType(targetType);
    // A type parameter is neither nullable nor non-nullable for the type
    // system; only a definitely non-nullable result is reported.
    if (resultType != null && context.typeSystem.isNonNullable(resultType)) {
      rule.reportAtNode(node.methodName, arguments: [resultType.getDisplayString()]);
    }
  }
}
