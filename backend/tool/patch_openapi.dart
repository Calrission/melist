import 'dart:convert';
import 'dart:io';

import 'package:melist_backend/melist_backend.dart';

/// Overwrites `info` in `build/openapi.json` from pubspec.
///
/// `dart_frog_swagger` always writes "Dart Frog API" / "1.0.0".
void main() {
  const path = 'build/openapi.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln(
      '$path is missing. Run dart run dart_frog_swagger first.',
    );
    exitCode = 1;
    return;
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    stderr.writeln('$path is not a JSON object');
    exitCode = 1;
    return;
  }

  final spec = <String, dynamic>{
    for (final entry in decoded.entries) entry.key.toString(): entry.value,
  };
  applyOpenApiInfo(spec);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(spec)}\n',
  );
}
