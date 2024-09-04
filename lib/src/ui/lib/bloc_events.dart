import 'package:flutter/widgets.dart';

@immutable
abstract interface class BlocEvent {}

@immutable
class BlocEvents {
  const BlocEvents._();

  static OnInit init({Object? arguments}) => OnInit._(arguments: arguments);
}

@immutable
class OnInit implements BlocEvent {
  final Object? arguments;

  OnInit._({this.arguments});

  @override
  String toString() {
    return 'OnInit{arguments: $arguments}';
  }
}
