import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

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
