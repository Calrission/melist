import 'package:postgres/postgres.dart';

/// Parsed `DATABASE_URL` plus pool limits.
///
/// Supported format:
/// `postgres://user:pass@host:5432/dbname?sslmode=disable&max_connections=10`
///
/// Query parameters:
/// - `sslmode`: `disable` (default), `require`, `verify-full`
///   (`allow`/`prefer` are treated as `require`, `verify-ca` as `verify-full`).
/// - `max_connections`: pool size, positive integer (default 10).
/// - `connect_timeout`, `query_timeout`: seconds, positive integers.
/// - `application_name`: shown in `pg_stat_activity` (default
///   `melist_backend`).
class DatabaseConfig {
  const DatabaseConfig({
    required this.endpoint,
    this.sslMode = SslMode.disable,
    this.maxConnections = defaultMaxConnections,
    this.connectTimeout,
    this.queryTimeout,
    this.applicationName = defaultApplicationName,
  });

  /// Parses a libpq-style connection URL. Throws [FormatException] with a
  /// human-readable message when the URL is malformed.
  factory DatabaseConfig.parse(String url) {
    if (url.trim().isEmpty) {
      throw const FormatException('DATABASE_URL is empty');
    }

    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException catch (e) {
      throw FormatException('DATABASE_URL is not a valid URI: ${e.message}');
    }

    if (uri.scheme != 'postgres' && uri.scheme != 'postgresql') {
      throw FormatException(
        'DATABASE_URL must start with postgres:// or postgresql://, '
        'got "${uri.scheme}://"',
      );
    }

    final params = uri.queryParameters;
    for (final key in params.keys) {
      if (!_knownParams.contains(key)) {
        throw FormatException('DATABASE_URL: unknown parameter "$key"');
      }
    }

    final database = params['database'] ?? uri.pathSegments.firstOrNull;
    if (database == null || database.isEmpty) {
      throw const FormatException(
        'DATABASE_URL must contain a database name: postgres://host/dbname',
      );
    }

    final (username, password) = _parseUserInfo(uri.userInfo);

    return DatabaseConfig(
      endpoint: Endpoint(
        host: uri.host.isEmpty ? 'localhost' : uri.host,
        port: _parsePort(params['port']) ?? (uri.port == 0 ? 5432 : uri.port),
        database: database,
        username: params['user'] ?? params['username'] ?? username,
        password: params['password'] ?? password,
      ),
      sslMode: _parseSslMode(params['sslmode']),
      maxConnections:
          _parsePositiveInt(params, 'max_connections') ??
          defaultMaxConnections,
      connectTimeout: _parseSeconds(params, 'connect_timeout'),
      queryTimeout: _parseSeconds(params, 'query_timeout'),
      applicationName: params['application_name'] ?? defaultApplicationName,
    );
  }

  static const defaultMaxConnections = 10;
  static const defaultApplicationName = 'melist_backend';

  static const _knownParams = {
    'application_name',
    'connect_timeout',
    'database',
    'max_connections',
    'password',
    'port',
    'query_timeout',
    'sslmode',
    'user',
    'username',
  };

  final Endpoint endpoint;
  final SslMode sslMode;
  final int maxConnections;
  final Duration? connectTimeout;
  final Duration? queryTimeout;
  final String applicationName;

  PoolSettings toPoolSettings() {
    return PoolSettings(
      maxConnectionCount: maxConnections,
      sslMode: sslMode,
      connectTimeout: connectTimeout,
      queryTimeout: queryTimeout,
      applicationName: applicationName,
    );
  }

  static (String?, String?) _parseUserInfo(String userInfo) {
    if (userInfo.isEmpty) {
      return (null, null);
    }
    final colon = userInfo.indexOf(':');
    if (colon == -1) {
      return (Uri.decodeComponent(userInfo), null);
    }
    return (
      Uri.decodeComponent(userInfo.substring(0, colon)),
      Uri.decodeComponent(userInfo.substring(colon + 1)),
    );
  }

  static int? _parsePort(String? raw) {
    if (raw == null) {
      return null;
    }
    final port = int.tryParse(raw);
    if (port == null || port <= 0 || port > 65535) {
      throw FormatException('DATABASE_URL: invalid port "$raw"');
    }
    return port;
  }

  static SslMode _parseSslMode(String? raw) {
    return switch (raw) {
      null || 'disable' => SslMode.disable,
      'allow' || 'prefer' || 'require' => SslMode.require,
      'verify-ca' || 'verify-full' => SslMode.verifyFull,
      _ => throw FormatException(
        'DATABASE_URL: invalid sslmode "$raw" '
        '(expected disable, require or verify-full)',
      ),
    };
  }

  static int? _parsePositiveInt(Map<String, String> params, String key) {
    final raw = params[key];
    if (raw == null) {
      return null;
    }
    final value = int.tryParse(raw);
    if (value == null || value <= 0) {
      throw FormatException(
        'DATABASE_URL: $key must be a positive integer, got "$raw"',
      );
    }
    return value;
  }

  static Duration? _parseSeconds(Map<String, String> params, String key) {
    final seconds = _parsePositiveInt(params, key);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
