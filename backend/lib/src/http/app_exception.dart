import 'dart:io';

/// Domain error that a route converts into `{ "error": "..." }`.
sealed class AppException implements Exception {
  const AppException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'AppException($statusCode, $message)';
}

final class BadRequestException extends AppException {
  const BadRequestException(String message)
    : super(HttpStatus.badRequest, message);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'Forbidden'])
    : super(HttpStatus.forbidden, message);
}

final class NotFoundException extends AppException {
  const NotFoundException([String message = 'Not found'])
    : super(HttpStatus.notFound, message);
}
