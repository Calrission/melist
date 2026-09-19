import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:melist_backend/melist_backend.dart';

/// Custom Dart Frog entrypoint: runs once before the server starts listening.
///
/// Everything that must be valid for the process to be useful is resolved
/// here, so a broken `.env` or an unreachable PostgreSQL fails the start
/// instead of the first request:
/// 1. `AppConfig.load()` — required env variables present;
/// 2. `Database.fromUrl` — `DATABASE_URL` well-formed;
/// 3. `Database.connect()` — server reachable, credentials accepted;
/// 4. `Migrator.migrate()` — schema exists and matches `allMigrations`;
///    missing tables are created, a failing migration aborts the start.
///
/// The resulting singletons are injected with `provider` above the whole
/// router, so `routes/**` read them via `context.read<T>()`.
/// When `DEBUG_AUTH=true`, the debug user is upserted and a fixed Bearer
/// string is accepted under `/api/**`.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final config = AppConfig.load();
  final debugAuth = DebugAuth.fromConfig(config);
  final database = Database.fromUrl(config.databaseUrl);

  try {
    await database.connect();
    stdout.writeln('Connected to PostgreSQL');

    final report = await Migrator(
      database,
      log: (message) => stdout.writeln('[migrations] $message'),
    ).migrate();
    stdout.writeln('[migrations] $report');

    if (debugAuth.enabled) {
      await UserRepository(database).ensure(debugAuth.user);
      stdout.writeln(
        'Debug auth enabled: user ${debugAuth.user.id} '
        '(${debugAuth.user.username}), Bearer ${debugAuth.token}',
      );
    }
  } on Object catch (error) {
    await database.close(force: true);
    stderr.writeln('Database startup failed: $error');
    rethrow;
  }

  final server = await serve(
    handler
        .use(provider<AppConfig>((_) => config))
        .use(provider<Database>((_) => database))
        .use(provider<DebugAuth>((_) => debugAuth)),
    ip,
    port,
  );

  _closeOnShutdown(server, database);
  return server;
}

/// Closes the pool when the process receives SIGINT/SIGTERM
/// (Ctrl+C in `dart_frog dev`, `docker stop` in production).
void _closeOnShutdown(HttpServer server, Database database) {
  var closing = false;
  Future<void> shutdown(ProcessSignal signal) async {
    if (closing) {
      return;
    }
    closing = true;
    stdout.writeln('Received $signal, shutting down');
    await server.close(force: true);
    await database.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }
}
