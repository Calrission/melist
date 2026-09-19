import 'package:dart_frog/dart_frog.dart';

/// Parses a JSON object body. Returns `null` when the body is missing,
/// not an object, or not valid JSON.
Future<Map<String, dynamic>?> readJsonMap(Request request) async {
  try {
    final body = await request.json();
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return null;
  } on Object {
    return null;
  }
}
