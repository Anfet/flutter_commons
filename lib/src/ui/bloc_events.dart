import 'package:flutter/widgets.dart';

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

  static BlocEvent init({BlocArguments? arguments}) => OnInit._(arguments: arguments);

  static BlocEvent updateState<T extends BlocState>(T newState) => UpdateState._(newState);

  static BlocEvent returnResult(dynamic data) => ReturnResult._(data);
}

@immutable
class OnInit extends BlocEvent {
  final BlocArguments? arguments;

  OnInit._({this.arguments});

  @override
  String toString() {
    return 'OnInit{arguments: $arguments}';
  }

  BlocArguments get requiredArgs => arguments ?? {};
}

@immutable
class UpdateState<T extends BlocState> extends BlocEvent {
  final T newState;

  UpdateState._(this.newState);

  @override
  String toString() {
    return 'UpdateState{newState: $newState}';
  }
}

@immutable
class ReturnResult extends BlocEvent {
  final dynamic data;

  ReturnResult._(this.data);

  @override
  String toString() {
    return 'ReturnResult{data: $data}';
  }
}
