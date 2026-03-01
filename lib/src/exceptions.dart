dynamic throwIfNull([String? text]) => throw IllegalArgumentException(text ?? "Value is null");

dynamic throwWtf([String? text]) => throw WtfException(text ?? "Value is null");

dynamic throwE(Exception exception) => throw exception;

/// Public class AppException.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  AppException.fromOther(Object error) : this(error.toString());

  @override
  String toString() => message;
}

/// Public class WtfException.
class WtfException extends AppException {
  WtfException(super.message);
}

/// Public class IllegalArgumentException.
class IllegalArgumentException extends AppException {
  IllegalArgumentException(super.message);
}

/// Public class ListIsEmptyException.
class ListIsEmptyException extends AppException {
  ListIsEmptyException([super.message = 'List is empty']);
}

/// Public class NotImplementedException.
class NotImplementedException extends AppException {
  NotImplementedException() : super("Not implemented, yet");
}

/// Public class ErrorHandledException.
class ErrorHandledException extends AppException {
  ErrorHandledException() : super("Ok");
}

/// Public class FlowException.
class FlowException extends AppException {
  FlowException(super.message);
}

/// Public class SilentFlowException.
class SilentFlowException extends FlowException {
  SilentFlowException() : super('');
}

/// Public class CancelledQueryException.
class CancelledQueryException extends FlowException {
  CancelledQueryException() : super('');

  @override
  String toString() {
    return 'CancelledQueryException{}';
  }
}
