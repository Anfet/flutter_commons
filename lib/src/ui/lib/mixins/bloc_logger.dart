import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_logger/flutter_logger.dart';

mixin BlocLogging<E, S> on Bloc<E, S> {
  String get _TAG => '$runtimeType';

  @override
  void onEvent(event) {
    super.onEvent(event);
    logMessage("\t <- $event", tag: _TAG);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    logMessage("\t <- error", level: LogLevel.error, error: error, stack: stackTrace, tag: _TAG);
  }
}
