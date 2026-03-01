import 'package:flutter/widgets.dart';

@immutable
abstract interface class BlocEvent {}

@immutable
/// Public class BlocEvents.
class BlocEvents {
  const BlocEvents._();

  static OnInit init({Object? arguments}) => OnInit._(arguments: arguments);
}

@immutable
/// Public class OnInit.
class OnInit implements BlocEvent {
  final Object? arguments;

  const OnInit._({this.arguments});

  @override
  String toString() {
    return 'OnInit{arguments: $arguments}';
  }
}
