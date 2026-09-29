import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Relative to the Dart Frog working directory (`backend/`).
///
/// `build-dev` writes `frontend/build/web`. `build-release` writes
/// `frontend/.build/web`. The directory that contains the newer
/// `index.html` is served; if neither exists yet, the dev path is used
/// so a later build is picked up without a restart.
const frontendBuildCandidates = [
  '../frontend/build/web',
  '../frontend/.build/web',
];

/// Directory of the Flutter web build.
///
/// `WEB_ROOT` overrides [frontendBuildCandidates]. The directory does not
/// have to exist yet: [withFrontend] starts serving it as soon as
/// `index.html` appears.
Directory frontendWebRoot({
  Map<String, String>? environment,
  Directory? workingDirectory,
}) {
  final env = environment ?? Platform.environment;
  final cwd = workingDirectory ?? Directory.current;
  final configured = env['WEB_ROOT']?.trim();
  if (configured != null && configured.isNotEmpty) {
    if (_isAbsolute(configured)) {
      return Directory(configured);
    }
    return Directory.fromUri(cwd.uri.resolve(configured));
  }

  Directory? selected;
  DateTime? selectedModified;
  for (final relative in frontendBuildCandidates) {
    final directory = Directory.fromUri(cwd.uri.resolve('$relative/'));
    final index = File(_child(directory, 'index.html'));
    if (!index.existsSync()) {
      selected ??= directory;
      continue;
    }
    final modified = index.lastModifiedSync();
    if (selectedModified == null || modified.isAfter(selectedModified)) {
      selected = directory;
      selectedModified = modified;
    }
  }
  return selected!;
}

/// Serves [root] for paths that are not the API, and falls back to
/// `index.html` for client-side routes (`/wishlists`, …).
///
/// Reserved for [api]: `/api`, `/auth`, `/health`, `/docs`, `/openapi.json`.
/// Until `index.html` exists, every request goes to [api] (`GET /` stays the
/// JSON welcome). A build that appears later is picked up without a restart.
Handler withFrontend(Handler api, {required Directory root}) {
  Handler? files;
  return (context) async {
    final path = context.request.uri.path;
    if (!frontendBuildReady(root) || isBackendPath(path)) {
      return api(context);
    }
    final staticFiles = files ??= createStaticFileHandler(
      path: _withoutTrailingSeparator(root.absolute.path),
      defaultDocument: 'index.html',
    );
    final response = await staticFiles(context);
    if (response.statusCode != HttpStatus.notFound) {
      if (path == '/' || path == '/index.html') {
        return response.copyWith(
          headers: {HttpHeaders.cacheControlHeader: 'no-cache'},
        );
      }
      return response;
    }
    final method = context.request.method;
    if ((method == HttpMethod.get || method == HttpMethod.head) &&
        _isClientRoute(path)) {
      return _spaIndex(root, head: method == HttpMethod.head);
    }
    return response;
  };
}

/// Whether [root] contains a Flutter web `index.html`.
bool frontendBuildReady(Directory root) {
  return File(_child(root, 'index.html')).existsSync();
}

/// API, auth, health, and Swagger stay on the Dart Frog router.
bool isBackendPath(String path) {
  final normalized = _stripTrailingSlash(path);
  if (normalized == '/health' || normalized == '/openapi.json') {
    return true;
  }
  for (final prefix in const ['/api', '/auth', '/docs']) {
    if (normalized == prefix || normalized.startsWith('$prefix/')) {
      return true;
    }
  }
  return false;
}

bool _isClientRoute(String path) {
  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  final name = segments.isEmpty ? '' : segments.last;
  return !name.contains('.');
}

String _stripTrailingSlash(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

Future<Response> _spaIndex(Directory root, {required bool head}) async {
  final file = File(_child(root, 'index.html'));
  if (!file.existsSync()) {
    return Response(statusCode: HttpStatus.notFound, body: 'Not Found');
  }
  final headers = <String, Object>{
    HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
  };
  if (head) {
    headers[HttpHeaders.contentLengthHeader] = '${file.lengthSync()}';
    return Response(headers: headers);
  }
  return Response.bytes(
    body: await file.readAsBytes(),
    headers: headers,
  );
}

String _child(Directory directory, String name) {
  final separator = Platform.pathSeparator;
  final root = _withoutTrailingSeparator(directory.path);
  return '$root$separator$name';
}

String _withoutTrailingSeparator(String path) {
  final separator = Platform.pathSeparator;
  if (path.length > separator.length &&
      path.endsWith(separator) &&
      !RegExp(r'^[A-Za-z]:\\$').hasMatch(path)) {
    return path.substring(0, path.length - separator.length);
  }
  return path;
}

bool _isAbsolute(String path) {
  if (path.startsWith('/') || path.startsWith(r'\')) {
    return true;
  }
  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
}
