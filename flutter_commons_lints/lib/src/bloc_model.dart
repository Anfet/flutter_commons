import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';

/// Recognizes the `bloc` and `flutter_commons` types the rules are about.
///
/// Types are matched by name and package, so the rules keep working when the
/// declaring files inside those packages move.
extension KnownTypes on InterfaceType {
  bool get isBloc => _isFrom('bloc', 'Bloc');

  bool get isBlocEvent => _isFrom('flutter_commons', 'BlocEvent');

  bool get isOnInit => _isFrom('flutter_commons', 'OnInit');

  bool get isWaitableEvent => _isFrom('flutter_commons', 'WaitableEvent');

  bool get isBlocWidgetState => _isFrom('flutter_commons', 'BlocWidgetState');

  bool get isAutoCloseWaitableEvents => _isFrom('flutter_commons', 'AutoCloseWaitableEvents');

  bool _isFrom(String package, String name) {
    final uri = element.library.uri;
    return element.name == name && uri.scheme == 'package' && uri.pathSegments.first == package;
  }
}

/// The `Bloc<E, S>` supertype of [element], or `null` when it is not a Bloc.
InterfaceType? blocSupertypeOf(InterfaceElement element) => supertypeOf(element, (type) => type.isBloc);

/// The first supertype of [element] (including itself) that satisfies [test].
InterfaceType? supertypeOf(InterfaceElement element, bool Function(InterfaceType type) test) {
  if (test(element.thisType)) {
    return element.thisType;
  }
  for (final type in element.allSupertypes) {
    if (test(type)) {
      return type;
    }
  }
  return null;
}

/// Whether `OnInit` can be added to a Bloc whose event type is [eventType].
///
/// `OnInit` implements only `BlocEvent`. Blocs typed with `Object` or
/// `dynamic` events are not `flutter_commons` Blocs and are ignored.
bool acceptsOnInit(DartType eventType) => eventType is InterfaceType && (eventType.isBlocEvent || eventType.isOnInit);

/// The result type `T` of a `WaitableEvent<T>` implemented by [type], if any.
DartType? waitableResultType(DartType? type) {
  if (type is! InterfaceType) {
    return null;
  }
  final waitable = supertypeOf(type.element, (it) => it.isWaitableEvent);
  if (waitable == null) {
    return null;
  }
  return type.asInstanceOf(waitable.element)?.typeArguments.single;
}

/// Whether completing a wait without a result is valid for [resultType].
bool allowsEmptyResult(TypeSystem typeSystem, DartType resultType) => resultType is VoidType || typeSystem.isNullable(resultType);

/// One `on<X>(handler)` registration in a Bloc constructor.
class EventRegistration {
  EventRegistration(this.invocation, this.eventType, this.handler);

  final MethodInvocation invocation;

  /// The type argument `X`; `null` when it is missing or unresolved.
  final DartType? eventType;

  /// The first argument: a method reference or a function expression.
  final Expression? handler;
}

/// The constructors of [node] and the `on<X>(...)` registrations they make.
extension BlocDeclaration on ClassDeclaration {
  Iterable<ConstructorDeclaration> get constructors => body.members.whereType<ConstructorDeclaration>();

  Iterable<MethodDeclaration> get methods => body.members.whereType<MethodDeclaration>();

  MethodDeclaration? method(String name) {
    for (final method in methods) {
      if (method.name.lexeme == name) {
        return method;
      }
    }
    return null;
  }

  List<EventRegistration> get eventRegistrations {
    final collector = _RegistrationCollector();
    for (final constructor in constructors) {
      constructor.body.accept(collector);
    }
    return collector.registrations;
  }
}

class _RegistrationCollector extends RecursiveAstVisitor<void> {
  final List<EventRegistration> registrations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (node.methodName.name == 'on' && (target == null || target is ThisExpression)) {
      final typeArguments = node.typeArgumentTypes;
      final arguments = node.argumentList.arguments;
      registrations.add(
        EventRegistration(
          node,
          typeArguments == null || typeArguments.isEmpty ? null : typeArguments.single,
          arguments.isEmpty ? null : arguments.first.argumentExpression,
        ),
      );
    }
    super.visitMethodInvocation(node);
  }
}
