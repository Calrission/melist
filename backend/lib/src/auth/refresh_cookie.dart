import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// HttpOnly refresh cookie. Path is `/auth` so `/api/v1/**` never sees it.
class RefreshCookie {
  const RefreshCookie._();

  static const name = 'refresh_token';
  static const path = '/auth';

  static String set({
    required String token,
    required Duration maxAge,
    required bool secure,
  }) {
    return _header(
      value: token,
      maxAge: maxAge.inSeconds,
      secure: secure,
    );
  }

  static String clear({required bool secure}) {
    return _header(value: '', maxAge: 0, secure: secure);
  }

  static String? read(Request request) {
    return readHeader(request.headers[HttpHeaders.cookieHeader]);
  }

  static String? readHeader(String? cookieHeader) {
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }

    for (final part in cookieHeader.split(';')) {
      final trimmed = part.trim();
      final eq = trimmed.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final key = trimmed.substring(0, eq).trim();
      if (key != name) {
        continue;
      }
      final value = trimmed.substring(eq + 1).trim();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  static String _header({
    required String value,
    required int maxAge,
    required bool secure,
  }) {
    final parts = <String>[
      '$name=$value',
      'Path=$path',
      'Max-Age=$maxAge',
      'HttpOnly',
      'SameSite=Lax',
      if (secure) 'Secure',
    ];
    return parts.join('; ');
  }
}
