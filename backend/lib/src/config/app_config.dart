import 'package:dotenv/dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.botToken,
    required this.jwtSecret,
    this.initDataMaxAge = const Duration(hours: 24),
    this.accessTokenTtl = const Duration(hours: 1),
  });

  factory AppConfig.load({List<String> files = const ['.env']}) {
    final env = DotEnv(includePlatformEnvironment: true)..load(files);
    return AppConfig.fromEnv(env);
  }

  factory AppConfig.fromEnv(DotEnv env) {
    return AppConfig(
      botToken: _require(env, 'BOT_TOKEN'),
      jwtSecret: _require(env, 'JWT_SECRET'),
    );
  }

  final String botToken;
  final String jwtSecret;
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
