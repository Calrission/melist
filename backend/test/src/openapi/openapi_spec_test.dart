import 'dart:io';

import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

void main() {
  group('applyOpenApiBearerAuth', () {
    test('registers bearerAuth and locks only /api routes', () {
      final spec = <String, dynamic>{
        'openapi': '3.0.0',
        'paths': <String, dynamic>{
          '/auth/debug': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'debug'},
          },
          '/api/wishlists': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'list'},
            'parameters': <Map<String, Object>>[],
          },
        },
      };

      applyOpenApiBearerAuth(spec);

      final schemes =
          (spec['components'] as Map<String, dynamic>)['securitySchemes']
              as Map<String, dynamic>;
      expect(schemes['bearerAuth'], isA<Map<String, Object?>>());
      expect(
        (schemes['bearerAuth'] as Map<String, Object?>)['scheme'],
        'bearer',
      );

      final authDebug =
          (spec['paths'] as Map<String, dynamic>)['/auth/debug']
              as Map<String, dynamic>;
      expect(authDebug.containsKey('security'), isFalse);
      expect(
        (authDebug['get'] as Map<String, dynamic>).containsKey('security'),
        isFalse,
      );

      final wishlists =
          (spec['paths'] as Map<String, dynamic>)['/api/wishlists']
              as Map<String, dynamic>;
      expect(
        (wishlists['get'] as Map<String, dynamic>)['security'],
        equals([
          {'bearerAuth': <String>[]},
        ]),
      );
      expect(wishlists['parameters'], isA<List<Object?>>());
    });

    test('keeps existing components when present', () {
      final spec = <String, dynamic>{
        'components': {
          'schemas': {'Error': <String, Object>{}},
        },
        'paths': <String, Object>{},
      };

      applyOpenApiBearerAuth(spec);

      final components = spec['components'] as Map<String, dynamic>;
      expect(components['schemas'], isNotNull);
      expect(components['securitySchemes'], isNotNull);
    });
  });

  group('applyOpenApiPathParameters', () {
    test('declares path params from the template', () {
      final spec = <String, dynamic>{
        'paths': <String, dynamic>{
          '/api/wishlists/{id}/wishes/{wishId}': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'item'},
          },
          '/api/shared/{token}': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'share'},
          },
          '/api/wishlists': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'list'},
          },
        },
      };

      applyOpenApiPathParameters(spec);
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(
        (paths['/api/wishlists/{id}/wishes/{wishId}']
            as Map<String, dynamic>)['parameters'],
        equals([
          {
            'name': 'id',
            'in': 'path',
            'required': true,
            'schema': {'type': 'integer'},
          },
          {
            'name': 'wishId',
            'in': 'path',
            'required': true,
            'schema': {'type': 'integer'},
          },
        ]),
      );
      expect(
        (paths['/api/shared/{token}'] as Map<String, dynamic>)['parameters'],
        equals([
          {
            'name': 'token',
            'in': 'path',
            'required': true,
            'schema': {'type': 'string'},
          },
        ]),
      );
      expect(
        (paths['/api/wishlists'] as Map<String, dynamic>).containsKey(
          'parameters',
        ),
        isFalse,
      );
    });

    test('does not duplicate an existing parameter', () {
      final spec = <String, dynamic>{
        'paths': <String, dynamic>{
          '/api/users/{id}': <String, dynamic>{
            'get': <String, dynamic>{'summary': 'user'},
            'parameters': [
              {
                'name': 'id',
                'in': 'path',
                'required': true,
                'schema': {'type': 'string'},
              },
            ],
          },
        },
      };

      applyOpenApiPathParameters(spec);
      final item =
          (spec['paths'] as Map<String, dynamic>)['/api/users/{id}']
              as Map<String, dynamic>;
      expect(item['parameters'] as List<Object?>, hasLength(1));
    });
  });

  test('applyOpenApiSpec adds both bearer and path params', () {
    final spec = <String, dynamic>{
      'paths': <String, dynamic>{
        '/api/wishlists/{id}': <String, dynamic>{
          'get': <String, dynamic>{'summary': 'card'},
        },
      },
    };

    applyOpenApiSpec(spec);
    final item =
        (spec['paths'] as Map<String, dynamic>)['/api/wishlists/{id}']
            as Map<String, dynamic>;

    expect(item['parameters'], isNotEmpty);
    expect(
      (item['get'] as Map<String, dynamic>)['security'],
      isNotNull,
    );
    expect(
      (spec['info'] as Map<String, dynamic>)['title'],
      openApiTitle,
    );
    expect(
      (spec['info'] as Map<String, dynamic>)['version'],
      packageVersion(),
    );
  });

  group('applyOpenApiInfo', () {
    test('replaces Dart Frog defaults with pubspec version', () {
      final spec = <String, dynamic>{
        'info': {'title': 'Dart Frog API', 'version': '1.0.0'},
        'paths': <String, Object>{},
      };

      applyOpenApiInfo(spec);

      final info = spec['info'] as Map<String, dynamic>;
      expect(info['title'], openApiTitle);
      expect(info['version'], packageVersion());
      expect(info['version'], isNot('1.0.0'));
    });

    test('uses an explicit version when given', () {
      final spec = <String, dynamic>{'paths': <String, Object>{}};
      applyOpenApiInfo(spec, version: '9.9.9');
      expect(
        (spec['info'] as Map<String, dynamic>)['version'],
        '9.9.9',
      );
    });
  });

  group('parsePubspecVersion', () {
    test('reads the version field', () {
      expect(parsePubspecVersion('name: x\nversion: 0.1.1\n'), '0.1.1');
      expect(parsePubspecVersion("version: '1.2.3+4'\n"), '1.2.3+4');
    });
  });
}
