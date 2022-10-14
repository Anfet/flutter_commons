import 'package:logger/logger.dart';
import 'package:siberian_core/siberian_core.dart';

extension AnyExt<T> on T {
  X let<X>(X Function(T it) block) => block.call(this);

  T use(void Function(T it) block) {
    block.call(this);
    return this;
  }

  T? takeIf(bool Function(T it) mapper) => mapper.call(this) ? this : null;

  T? takeUnless(bool Function(T it) mapper) => mapper.call(this) ? null : this;

  bool containsIn(List<T> list) => list.contains(this);

  void logMessage(String message, {String? tag, Level level = Level.verbose, dynamic error, StackTrace? stackTrace}) =>
      GlobalLogger.instance
          .logMessage(message, level: level, tag: "$runtimeType", error: error, stackTrace: stackTrace);
}
