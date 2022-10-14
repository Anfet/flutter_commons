import 'package:flutter/widgets.dart';
import 'package:siberian_core/siberian_core.dart';

import 'bloc_arguments.dart';
import 'bloc_state.dart';

int _eid = 0;

@immutable
abstract class BlocEvent {
  final int eventId = ++_eid;

  @override
  String toString() => "$runtimeType";

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlocEvent && runtimeType == other.runtimeType && eventId == other.eventId;

  @override
  int get hashCode => eventId.hashCode;
}

@immutable
class BlocEvents {
  const BlocEvents._();

  static BlocEvent init({Object? arguments}) => OnInit._(arguments: arguments);

  static BlocEvent updateState<T extends BlocState>(T newState) => UpdateState._(newState);

  static BlocEvent updateLoader(Lce newState) => UpdateLoader._(newState);

  static BlocEvent returnResult(dynamic data) => ReturnResult._(data);
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

@immutable
class UpdateState<T extends BlocState> extends BlocEvent {
  final T newState;

  UpdateState._(this.newState);

  @override
  String toString() {
    return 'UpdateState{newState: $newState}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is UpdateState && runtimeType == other.runtimeType && newState == other.newState;

  @override
  int get hashCode => super.hashCode ^ newState.hashCode;
}

@immutable
class UpdateLoader extends BlocEvent {
  final Lce<dynamic> newState;

  UpdateLoader._(this.newState);

  @override
  String toString() {
    return 'UpdateLoader{newState: $newState}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is UpdateLoader && runtimeType == other.runtimeType && newState == other.newState;

  @override
  int get hashCode => super.hashCode ^ newState.hashCode;
}

@immutable
class ReturnResult extends BlocEvent {
  final dynamic data;

  ReturnResult._(this.data);

  @override
  String toString() {
    return 'ReturnResult{data: $data}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is ReturnResult && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => super.hashCode ^ data.hashCode;
}
