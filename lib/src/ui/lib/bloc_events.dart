import 'package:flutter/widgets.dart';

int _eid = 0;

@immutable
abstract class BlocEvent {
  final int eventId = ++_eid;

  @override
  String toString() => "$runtimeType";

  @override
  bool operator ==(Object other) => identical(this, other) || other is BlocEvent && runtimeType == other.runtimeType && eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}

@immutable
class BlocEvents {
  const BlocEvents._();

  static OnInit init({Object? arguments}) => OnInit._(arguments: arguments);
}

@immutable
class OnInit extends BlocEvent {
  final Object? arguments;

  OnInit._({this.arguments});

  @override
  String toString() {
    return 'OnInit{arguments: $arguments}';
  }
}
