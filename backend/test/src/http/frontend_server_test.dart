import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('melist_frontend_');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Directory webRoot([String folder = 'build']) => Directory(
    '${tmp.path}${Platform.pathSeparator}frontend'
    '${Platform.pathSeparator}$folder${Platform.pathSeparator}web',
  );

  void writeWeb(String name, String contents) {
    final root = webRoot()..createSync(recursive: true);
    File(
      '${root.path}${Platform.pathSeparator}$name',
    ).writeAsStringSync(contents);
  }

  Handler apiEcho() {
    return (context) {
      return Response(body: 'api:${context.request.uri.path}');
    };
  }

  group('frontendWebRoot', () {
    test('defaults to frontend/build/web when nothing is built', () {
      final backend = Directory(
        '${tmp.path}${Platform.pathSeparator}backend',
      )..createSync();

      final root = frontendWebRoot(
        environment: const {},
        workingDirectory: backend,
      );

      expect(_normalize(root.path), _normalize(webRoot().path));
    });

    test('uses the build directory that contains index.html', () {
      final backend = Directory(
        '${tmp.path}${Platform.pathSeparator}backend',
      )..createSync();
      final release = webRoot('.build')..createSync(recursive: true);
      File(
        '${release.path}${Platform.pathSeparator}index.html',
      ).writeAsStringSync('<html>release</html>');

      final root = frontendWebRoot(
        environment: const {},
        workingDirectory: backend,
      );

      expect(_normalize(root.path), _normalize(release.path));
    });

    test('prefers the newer index.html when both builds exist', () {
      final backend = Directory(
        '${tmp.path}${Platform.pathSeparator}backend',
      )..createSync();
      final dev = webRoot()..createSync(recursive: true);
      final release = webRoot('.build')..createSync(recursive: true);
      final devIndex = File(
        '${dev.path}${Platform.pathSeparator}index.html',
      )..writeAsStringSync('<html>dev</html>');
      File(
        '${release.path}${Platform.pathSeparator}index.html',
      ).writeAsStringSync('<html>release</html>');
      devIndex.setLastModifiedSync(
        DateTime.now().add(const Duration(minutes: 1)),
      );

      final root = frontendWebRoot(
        environment: const {},
        workingDirectory: backend,
      );

      expect(_normalize(root.path), _normalize(dev.path));
    });

    test('WEB_ROOT overrides the default, including a relative path', () {
      final backend = Directory(
        '${tmp.path}${Platform.pathSeparator}backend',
      )..createSync();
      final custom = Directory(
        '${tmp.path}${Platform.pathSeparator}custom',
      );

      final root = frontendWebRoot(
        environment: const {'WEB_ROOT': '../custom'},
        workingDirectory: backend,
      );

      expect(_normalize(root.path), _normalize(custom.path));
    });
  });

  group('isBackendPath', () {
    test('reserves API, auth, health, and Swagger', () {
      expect(isBackendPath('/health'), isTrue);
      expect(isBackendPath('/api/me'), isTrue);
      expect(isBackendPath('/auth/validate'), isTrue);
      expect(isBackendPath('/docs'), isTrue);
      expect(isBackendPath('/openapi.json'), isTrue);
      expect(isBackendPath('/'), isFalse);
      expect(isBackendPath('/wishlists'), isFalse);
      expect(isBackendPath('/authentication'), isFalse);
    });
  });

  group('withFrontend', () {
    test('delegates everything until index.html exists', () async {
      final handler = withFrontend(apiEcho(), root: webRoot());
      final response = await handler(
        TestRequestContext(path: '/').context,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.body(), 'api:/');
    });

    test('serves index.html at / and client routes', () async {
      writeWeb('index.html', '<html>app</html>');
      final handler = withFrontend(apiEcho(), root: webRoot());

      final home = await handler(TestRequestContext(path: '/').context);
      final wishlist = await handler(
        TestRequestContext(path: '/wishlists/edit/1').context,
      );

      expect(home.statusCode, HttpStatus.ok);
      expect(await home.body(), '<html>app</html>');
      expect(home.headers['content-type'], contains('text/html'));
      expect(home.headers['cache-control'], 'no-cache');
      expect(wishlist.statusCode, HttpStatus.ok);
      expect(await wishlist.body(), '<html>app</html>');
      expect(wishlist.headers['cache-control'], 'no-cache');
    });

    test('serves a static asset and 404s a missing one', () async {
      writeWeb('index.html', '<html>app</html>');
      writeWeb('main.dart.js', 'console.log(1)');
      final handler = withFrontend(apiEcho(), root: webRoot());

      final asset = await handler(
        TestRequestContext(path: '/main.dart.js').context,
      );
      final missing = await handler(
        TestRequestContext(path: '/missing.js').context,
      );

      expect(await asset.body(), 'console.log(1)');
      expect(missing.statusCode, HttpStatus.notFound);
      expect(await missing.body(), isNot(contains('<html>')));
    });

    test('keeps API paths on the router', () async {
      writeWeb('index.html', '<html>app</html>');
      writeWeb('health', 'file');
      final handler = withFrontend(apiEcho(), root: webRoot());

      for (final path in [
        '/health',
        '/api/me',
        '/auth/validate',
        '/docs',
        '/openapi.json',
      ]) {
        final response = await handler(
          TestRequestContext(path: path).context,
        );
        expect(await response.body(), 'api:$path');
      }
    });

    test('does not rewrite a non-GET client route to HTML', () async {
      writeWeb('index.html', '<html>app</html>');
      final handler = withFrontend(apiEcho(), root: webRoot());

      final response = await handler(
        TestRequestContext(path: '/wishlists', method: HttpMethod.post).context,
      );

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('picks up a build that appears after startup', () async {
      final handler = withFrontend(apiEcho(), root: webRoot());
      final before = await handler(TestRequestContext(path: '/').context);
      expect(await before.body(), 'api:/');

      writeWeb('index.html', '<html>later</html>');
      final after = await handler(TestRequestContext(path: '/').context);
      expect(await after.body(), '<html>later</html>');
    });
  });
}

String _normalize(String path) {
  return path.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
}
