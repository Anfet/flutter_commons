import 'package:flutter_commons/src/exceptions.dart';

T require<T>(T? obj) {
  if (obj == null) {
    throw RequireException('required obj is null');
  }

  return obj;
}

class RequireException extends AppException {
  RequireException(super.message);
}
