import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/src/http/app_exception.dart';

/// Unified error payload: `{ "error": "<message>" }`.
Response errorResponse(int statusCode, String message) {
  return Response.json(
    statusCode: statusCode,
    body: {'error': message},
  );
}

Response badRequest(String message) {
  return errorResponse(HttpStatus.badRequest, message);
}

Response forbidden([String message = 'Forbidden']) {
  return errorResponse(HttpStatus.forbidden, message);
}

Response notFound([String message = 'Not found']) {
  return errorResponse(HttpStatus.notFound, message);
}

Response created(Object body) {
  return Response.json(statusCode: HttpStatus.created, body: body);
}

Response noContent() {
  return Response(statusCode: HttpStatus.noContent);
}

/// Maps [AppException] onto `{ "error": "..." }` with the matching status.
Response appError(AppException error) {
  return errorResponse(error.statusCode, error.message);
}

Response methodNotAllowed() {
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// Placeholder for endpoints that are designed but not implemented yet.
Response notImplemented() {
  return errorResponse(HttpStatus.notImplemented, 'Not implemented');
}

/// Returns `405` when the request method is not in [allowed],
/// otherwise `null`.
Response? rejectUnlessMethod(
  RequestContext context,
  Set<HttpMethod> allowed,
) {
  if (allowed.contains(context.request.method)) {
    return null;
  }
  return methodNotAllowed();
}
