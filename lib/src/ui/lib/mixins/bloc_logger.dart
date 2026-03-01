import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_commons/src/logging.dart';

/// Public mixin BlocLogging.
mixin BlocLogging<E, S> on Bloc<E, S> {
  String get _tag => '$runtimeType';

  @override
  void onEvent(event) {
    super.onEvent(event);
    logMessage("\t <- $event", tag: _tag);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    logMessage("\t <- error", error: error, stack: stackTrace, tag: _tag);
  }
}
