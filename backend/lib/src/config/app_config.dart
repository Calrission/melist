import 'dart:io';

import 'package:dotenv/dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.botToken,
    required this.jwtSecret,
    required this.databaseUrl,
    this.initDataMaxAge = const Duration(hours: 24),
    this.accessTokenTtl = const Duration(hours: 1),
    this.debugAuth = false,
    this.debugToken,
    this.debugUserId = 1,
    this.botUsername = 'melist_bot',
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
      debugAuth: _flag(env, 'DEBUG_AUTH'),
      debugToken: _optional(env, 'DEBUG_TOKEN'),
      debugUserId: _positiveInt(env, 'DEBUG_USER_ID', 1),
      botUsername: _botUsername(env),
    );
  }

  final String botToken;
  final String jwtSecret;

  /// PostgreSQL connection string, e.g.
  /// `postgres://user:pass@localhost:5432/melist?sslmode=disable`.
  final String databaseUrl;
  final Duration initDataMaxAge;
  final Duration accessTokenTtl;

  /// When true, `Authorization: Bearer <DEBUG_TOKEN>` logs in as [debugUserId]
  /// without Telegram. Must stay false in production.
  final bool debugAuth;
  final String? debugToken;
  final int debugUserId;

  /// Telegram bot username without `@`, used in Mini App share links (7.1).
  final String botUsername;

  static String _require(DotEnv env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      throw StateError('$key is not set');
    }
    return value;
  }

  static String? _optional(DotEnv env, String key) {
    final value = env[key];
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static bool _flag(DotEnv env, String key) {
    final raw = env[key]?.trim().toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static String _botUsername(DotEnv env) {
    final raw = _optional(env, 'BOT_USERNAME') ?? 'melist_bot';
    return raw.startsWith('@') ? raw.substring(1) : raw;
  }

  static int _positiveInt(DotEnv env, String key, int fallback) {
    final raw = env[key];
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    final value = int.tryParse(raw);
    if (value == null || value <= 0) {
      throw StateError('$key must be a positive integer');
    }
    return value;
  }
}
