import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as shelf;

/// Global middleware. `AppConfig` and `Database` are provided in `main.dart`
/// (created and verified once on startup); here only per-request services.
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(fromShelfMiddleware(shelf.corsHeaders()))
      .use(
        provider<InitDataValidator>((context) {
          final config = context.read<AppConfig>();
          return InitDataValidator(
            botToken: config.botToken,
            maxAge: config.initDataMaxAge,
          );
        }),
      )
      .use(
        provider<JwtService>((context) {
          final config = context.read<AppConfig>();
          return JwtService(
            secret: config.jwtSecret,
            accessTokenTtl: config.accessTokenTtl,
          );
        }),
      )
      .use(
        swaggerMiddleware(
          title: 'MELIST API',
          projectRoot: '.',
        ),
      );
}
