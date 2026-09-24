import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/data/interceptors/session_interceptor.dart';
import 'package:melist/data/network/dio_credentials.dart';
import 'package:melist/data/repository/api_repository.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/domain/models/config.dart';

Future<void> initDioModule(GetIt getIt) async {
  final config = getIt<Config>();
  final session = AuthSession();
  getIt.registerSingleton(session);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiUrl,
      headers: {Headers.contentTypeHeader: Headers.jsonContentType},
    ),
  );
  applyCredentials(dio);

  final api = ApiRepository(dio: dio, authSession: session);
  dio.interceptors.add(
    SessionInterceptor(
      session: session,
      dio: dio,
      refresh: () async {
        await api.refresh();
      },
    ),
  );

  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<IAuthRepository>(api);
  getIt.registerSingleton<IProfileRepository>(api);
}
