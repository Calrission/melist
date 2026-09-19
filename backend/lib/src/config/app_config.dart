import 'dart:io';

import 'package:dotenv/dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.botToken,
    required this.jwtSecret,
    required this.databaseUrl,
    this.initDataMaxAge = const Duration(hours: 24),
    this.accessTokenTtl = const Duration(hours: 1),
  });

  /// Reads [files] (`.env` by default), then overlays the process environment
  /// on top, so a variable exported in the shell / container always wins over
  /// the value in the file. Missing files are reported to stderr and skipped.
  factory AppConfig.load({
    List<String> files = const ['.env'],
    Map<String, String>? environment,
  }) {
    final env = DotEnv(quiet: true)
      ..load(files)
      ..addAll(environment ?? Platform.environment);
    return AppConfig.fromEnv(env);
  }

  factory AppConfig.fromEnv(DotEnv env) {
    return AppConfig(
      botToken: _require(env, 'BOT_TOKEN'),
      jwtSecret: _require(env, 'JWT_SECRET'),
      databaseUrl: _require(env, 'DATABASE_URL'),
    );
  }

  final String botToken;
  final String jwtSecret;

  /// PostgreSQL connection string, e.g.
  /// `postgres://user:pass@localhost:5432/melist?sslmode=disable`.
  final String databaseUrl;
  final Duration initDataMaxAge;
  final Duration accessTokenTtl;

  static String _require(DotEnv env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError('$key is not set');
    }
    return value;
  }
}
