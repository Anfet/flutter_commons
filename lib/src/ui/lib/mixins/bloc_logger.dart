import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_commons/src/logging.dart';

/// Logs every event added to a [Bloc] and every error it reports, tagged with
/// the Bloc's runtime type.
mixin BlocLogging<E, S> on Bloc<E, S> {
  String get _tag => '$runtimeType';

  @override
  void onEvent(E event) {
    super.onEvent(event);
    logMessage("\t <- $event", tag: _tag);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    logMessage("\t <- error", error: error, stack: stackTrace, tag: _tag);
  }
}
