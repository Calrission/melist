import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/version.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  RequestContext contextWith(Request request) {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(request);
    return context;
  }

  group('GET /version', () {
    test('responds with the pubspec version', () async {
      final response = route.onRequest(
        contextWith(Request.get(Uri.parse('http://localhost/version'))),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(
        jsonDecode(await response.body()),
        {'version': packageVersion()},
      );
    });

    test('responds with 405 when the method is not GET', () {
      final response = route.onRequest(
        contextWith(Request.post(Uri.parse('http://localhost/version'))),
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });
  });
}
