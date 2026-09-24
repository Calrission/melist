import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_swagger/dart_frog_swagger.dart';
import 'package:melist_backend/melist_backend.dart';

/// Global middleware. `AppConfig` and `Database` are provided in `main.dart`
/// (created and verified once on startup); here only per-request services.
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(applyCors)
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
        provider<AuthSessionService>((context) {
          final config = context.read<AppConfig>();
          return AuthSessionService.fromDatabase(
            context.read<Database>(),
            jwtService: JwtService(
              secret: config.jwtSecret,
              accessTokenTtl: config.accessTokenTtl,
            ),
            refreshTtl: config.refreshTokenTtl,
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
        provider<WishlistService>(
          (context) => WishlistService.fromDatabase(
            context.read<Database>(),
          ),
        ),
      )
      .use(
        provider<WishService>(
          (context) => WishService.fromDatabase(
            context.read<Database>(),
          ),
        ),
      )
      .use(
        provider<FavoriteService>(
          (context) => FavoriteService.fromDatabase(
            context.read<Database>(),
          ),
        ),
      )
      .use(
        provider<UserRepository>(
          (context) => UserRepository(context.read<Database>()),
        ),
      )
      .use(
        provider<ProfileService>(
          (context) => ProfileService.fromDatabase(
            context.read<Database>(),
          ),
        ),
      )
      .use(
        provider<SubscriptionService>(
          (context) => SubscriptionService.fromDatabase(
            context.read<Database>(),
          ),
        ),
      )
      .use(
        swaggerMiddleware(
          title: 'MELIST API',
          projectRoot: '.',
          transformJson: applyOpenApiSpec,
        ),
      );
}
