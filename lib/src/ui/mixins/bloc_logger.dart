import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:siberian_core/siberian_core.dart';

mixin BlocLogging<E, S> on Bloc<E, S> {
  @override
  void onEvent(event) {
    super.onEvent(event);
    logCustom("\t <- $event", level: Level.verbose, tag: "$runtimeType");
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    logCustom("\t <- error", level: Level.error, tag: "$runtimeType", error: error, stackTrace: stackTrace);
  }
}
