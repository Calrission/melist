import 'package:dio/dio.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/data/interceptors/session_interceptor.dart';
import 'package:melist/data/repository/api_repository.dart';
import 'package:melist/di/dio_provider.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_favorite_repository.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/domain/interfaces/i_subscriptions_repository.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/domain/models/config.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class _ApiGraph {
  _ApiGraph({
    required this.dio,
    required this.session,
    required this.repository,
  });

  factory _ApiGraph.create(Config config) {
    final dio = DioProvider.create(config);
    final repository = ApiRepository(dio: dio);
    final session = AuthSession(repository: repository);
    dio.interceptors.add(SessionInterceptor(session: session, dio: dio));
    return _ApiGraph(dio: dio, session: session, repository: repository);
  }

  final Dio dio;
  final AuthSession session;
  final ApiRepository repository;
}

class ApiMultiProvider {
  static List<SingleChildWidget> get providers => [
    Provider<_ApiGraph>(
      create: (ctx) => _ApiGraph.create(ctx.read<Config>()),
      dispose: (_, graph) => graph.dio.close(),
    ),
    ProxyProvider<_ApiGraph, Dio>(update: (_, graph, _) => graph.dio),
    ProxyProvider<_ApiGraph, AuthSession>(
      update: (_, graph, _) => graph.session,
    ),
    ProxyProvider<_ApiGraph, IAuthRepository>(
      update: (_, graph, _) => graph.repository,
    ),
    ProxyProvider<_ApiGraph, IProfileRepository>(
      update: (_, graph, _) => graph.repository,
    ),
    ProxyProvider<_ApiGraph, IWishlistRepository>(
      update: (_, graph, _) => graph.repository,
    ),
    ProxyProvider<_ApiGraph, IFavoriteRepository>(
      update: (_, graph, _) => graph.repository,
    ),
    ProxyProvider<_ApiGraph, IWishRepository>(
      update: (_, graph, _) => graph.repository,
    ),
    ProxyProvider<_ApiGraph, ISubscriptionsRepository>(
      update: (_, graph, _) => graph.repository,
    ),
  ];
}
