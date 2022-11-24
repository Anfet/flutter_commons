dynamic throwIfNull([String? text]) => throw IllegalArgumentException(text ?? "Value is null");
dynamic throwWtf([String? text]) => throw WtfException(text ?? "Value is null");

dynamic throwE(AppException exception) => throw exception;

class AppException implements Exception {
  final String message;

  const AppException(this.message);

  AppException.fromOther(Object error) : this(error.toString());

  @override
  String toString() {
    return '$runtimeType{message: $message}';
  }
}

class WtfException extends AppException {
  WtfException(super.message);
}

class IllegalArgumentException extends AppException {
  IllegalArgumentException(super.message);
}

class NotImplementedException extends AppException {
  NotImplementedException() : super("Not implemented, yet");
}

class ErrorHandledException extends AppException {
  ErrorHandledException() : super("Ok");
}

class FlowException extends AppException {
  FlowException(String message) : super(message);
}
