import 'package:flutter/foundation.dart';

void logMessage(
  Object? message, {
  Object? error,
  StackTrace? stack,
  String? tag,
}) {
  if (!kDebugMode) {
    return;
  }

  final buffer = StringBuffer();
  if (tag != null && tag.isNotEmpty) {
    buffer.write('[$tag]');
  }
  if (message != null) {
    buffer.write(' $message');
  }
  if (error != null) {
    buffer.write(' | error: $error');
  }

  debugPrint(buffer.toString());
  if (stack != null) {
    debugPrintStack(stackTrace: stack);
  }
}
