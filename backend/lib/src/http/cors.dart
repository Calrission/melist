import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/src/config/app_config.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as shelf;

/// Credentialed CORS when [AppConfig.corsOrigins] is set; otherwise allow-all
/// without credentials (same-origin proxy and curl).
///
/// Allowlist entries are exact origins or a single `*` label
/// (`https://*.ngrok-free.dev`).
Handler applyCors(Handler handler) {
  return (context) {
    final config = context.read<AppConfig>();
    final origin = context.request.headers['origin'];

    if (context.request.method == HttpMethod.options) {
      if (origin == null || !originIsAllowed(origin, config)) {
        return Response(statusCode: HttpStatus.noContent);
      }
      return Response(
        statusCode: HttpStatus.noContent,
        headers: _preflightHeaders(
          origin,
          credentials: config.corsOrigins.isNotEmpty,
        ),
      );
    }

    if (origin == null || !originIsAllowed(origin, config)) {
      return handler(context);
    }

    final cors = config.corsOrigins.isEmpty
        ? shelf.corsHeaders(
            headers: {shelf.ACCESS_CONTROL_ALLOW_CREDENTIALS: 'false'},
          )
        : shelf.corsHeaders(
            originChecker: (value) => originIsAllowed(value, config),
          );
    return fromShelfMiddleware(cors)(handler)(context);
  };
}

/// Whether [origin] may send credentialed (or allow-all) CORS requests.
bool originIsAllowed(String origin, AppConfig config) {
  if (config.corsOrigins.isEmpty) {
    return true;
  }
  return config.corsOrigins.any((pattern) => _matchesOrigin(pattern, origin));
}

Map<String, String> _preflightHeaders(
  String origin, {
  required bool credentials,
}) {
  return {
    HttpHeaders.accessControlAllowOriginHeader: origin,
    HttpHeaders.accessControlAllowCredentialsHeader: '$credentials',
    HttpHeaders.accessControlAllowHeadersHeader:
        'accept,accept-encoding,authorization,content-type,'
        'dnt,origin,user-agent',
    HttpHeaders.accessControlAllowMethodsHeader:
        'DELETE,GET,OPTIONS,PATCH,POST,PUT',
    HttpHeaders.accessControlMaxAgeHeader: '86400',
    HttpHeaders.varyHeader: 'Origin',
  };
}

bool _matchesOrigin(String pattern, String origin) {
  if (pattern == origin) {
    return true;
  }
  if ('*'.allMatches(pattern).length != 1) {
    return false;
  }
  final escaped = RegExp.escape(pattern).replaceAll(r'\*', '[A-Za-z0-9-]+');
  return RegExp('^$escaped\$').hasMatch(origin);
}
