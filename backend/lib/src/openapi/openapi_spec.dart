import 'dart:io';

/// Swagger UI page and OpenAPI `info.title`.
const openApiTitle = 'MELIST API';

/// Used when `pubspec.yaml` is not on disk (AOT image).
/// Keep equal to `version:` in `backend/pubspec.yaml`.
const openApiFallbackVersion = '0.1.0';

/// Patches the generated OpenAPI spec so Swagger UI is usable.
///
/// `dart_frog_swagger` does not emit `security` or path `parameters`,
/// and hardcodes `info` as "Dart Frog API" / "1.0.0".
Map<String, dynamic> applyOpenApiSpec(Map<String, dynamic> spec) {
  applyOpenApiPathParameters(spec);
  applyOpenApiBearerAuth(spec);
  applyOpenApiInfo(spec);
  return spec;
}

/// Sets `info.title` and `info.version` from [openApiTitle] and pubspec.
Map<String, dynamic> applyOpenApiInfo(
  Map<String, dynamic> spec, {
  String title = openApiTitle,
  String? version,
}) {
  final info = _asStringMap(spec['info']) ?? <String, dynamic>{};
  spec['info'] = info;
  info['title'] = title;
  info['version'] = version ?? packageVersion();
  return spec;
}

/// `version:` from the nearest `pubspec.yaml`, else [openApiFallbackVersion].
String packageVersion({
  List<String> candidatePaths = const [
    'pubspec.yaml',
    'backend/pubspec.yaml',
  ],
}) {
  for (final path in candidatePaths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    return parsePubspecVersion(file.readAsStringSync());
  }
  return openApiFallbackVersion;
}

String parsePubspecVersion(String yaml) {
  final match = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(yaml);
  var value = match?.group(1)?.trim() ?? '';
  final comment = value.indexOf('#');
  if (comment != -1) {
    value = value.substring(0, comment).trim();
  }
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    value = value.substring(1, value.length - 1);
  }
  if (value.isEmpty) {
    throw const FormatException('pubspec.yaml has no version');
  }
  return value;
}

/// Declares `{param}` segments as required path parameters.
Map<String, dynamic> applyOpenApiPathParameters(Map<String, dynamic> spec) {
  final rawPaths = spec['paths'];
  if (rawPaths is! Map) {
    return spec;
  }

  final paths = _asStringMap(rawPaths)!;
  spec['paths'] = paths;

  for (final path in paths.keys.toList()) {
    final names = [
      for (final match in _pathParamPattern.allMatches(path)) match.group(1)!,
    ];
    if (names.isEmpty) {
      continue;
    }

    final rawItem = paths[path];
    if (rawItem is! Map) {
      continue;
    }
    final item = _asStringMap(rawItem)!;
    paths[path] = item;

    final existing = _parameterNames(item['parameters']);
    final extra = [
      for (final name in names)
        if (!existing.contains(name)) _pathParameter(name),
    ];
    if (extra.isEmpty) {
      continue;
    }

    item['parameters'] = [..._asList(item['parameters']), ...extra];
  }

  return spec;
}

/// Adds Bearer auth so Swagger UI shows Authorize. Applied only to `/api/**`.
Map<String, dynamic> applyOpenApiBearerAuth(Map<String, dynamic> spec) {
  final components = _asStringMap(spec['components']) ?? <String, dynamic>{};
  spec['components'] = components;
  components['securitySchemes'] = {
    'bearerAuth': {
      'type': 'http',
      'scheme': 'bearer',
      'bearerFormat': 'JWT',
      'description':
          'Paste only the token, without the Bearer prefix. '
          'Use POST /auth/validate, GET /auth/debug, or DEBUG_TOKEN.',
    },
  };

  final rawPaths = spec['paths'];
  if (rawPaths is! Map) {
    return spec;
  }

  final paths = _asStringMap(rawPaths)!;
  spec['paths'] = paths;

  for (final path in paths.keys.toList()) {
    if (!path.startsWith('/api/')) {
      continue;
    }
    final rawOps = paths[path];
    if (rawOps is! Map) {
      continue;
    }
    final operations = _asStringMap(rawOps)!;
    paths[path] = operations;

    for (final method in operations.keys.toList()) {
      if (!_httpMethods.contains(method.toLowerCase())) {
        continue;
      }
      final rawOp = operations[method];
      if (rawOp is! Map) {
        continue;
      }
      final operation = _asStringMap(rawOp)!;
      operation['security'] = [
        {'bearerAuth': <String>[]},
      ];
      operations[method] = operation;
    }
  }

  return spec;
}

final _pathParamPattern = RegExp(r'\{([^}/]+)\}');

const _httpMethods = {
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
};

Map<String, Object> _pathParameter(String name) {
  final integer = name == 'id' || name.endsWith('Id');
  return {
    'name': name,
    'in': 'path',
    'required': true,
    'schema': {'type': integer ? 'integer' : 'string'},
  };
}

Set<String> _parameterNames(Object? parameters) {
  return {
    for (final item in _asList(parameters))
      if (item is Map && item['name'] is String) item['name'] as String,
  };
}

List<Object?> _asList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return List<Object?>.from(value);
  }
  return const [];
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }
  return null;
}
