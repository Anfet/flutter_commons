import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:siberian_logger/siberian_logger.dart';

mixin BlocLogging<E, S> on Bloc<E, S> {
  @override
  void onEvent(event) {
    super.onEvent(event);
    logMessage("\t <- $event", level: Level.trace, tag: "$runtimeType");
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    logMessage("\t <- error", level: Level.error, tag: "$runtimeType", error: error, stack: stackTrace);
  }
}
