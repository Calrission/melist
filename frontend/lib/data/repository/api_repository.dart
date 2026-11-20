import 'package:dio/dio.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_favorite_repository.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/domain/interfaces/i_subscriptions_repository.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist_core/melist_core.dart';

class ApiRepository
    implements
        IAuthRepository,
        IProfileRepository,
        IWishlistRepository,
        IFavoriteRepository,
        IWishRepository,
        ISubscriptionsRepository {
  final Dio _dio;

  ApiRepository({required this._dio});

  Future<String> getBackendVersion() async {
    final response = await _dio.get('/version');
    final version = _asMap(response.data)['version'];
    if (version is! String || version.isEmpty) {
      throw const FormatException('Backend version is missing');
    }
    return version;
  }

  @override
  Future<AuthSessionModel> login(AuthValidateBody body) {
    return _postSession('/auth/validate', data: body.toJson());
  }

  @override
  Future<AuthSessionModel> refresh() {
    return _postSession('/auth/refresh');
  }

  @override
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<AuthSessionModel> _postSession(String path, {Object? data}) async {
    final response = await _dio.post(path, data: data);
    return _parseSession(response.data);
  }

  @override
  Future<AuthSessionModel> loginDebug() async {
    final response = await _dio.get('/auth/debug');
    final raw = _asMap(response.data);
    return AuthSessionModel(
      accessToken: raw['accessToken'] as String,
      tokenType: raw['tokenType'] as String? ?? AuthSessionModel.bearer,
      expiresIn: (raw['expiresIn'] as num?)?.toInt() ?? 0,
      user: UserModel.fromJson(_asMap(raw['user'])),
    );
  }

  AuthSessionModel _parseSession(Object? data) {
    return AuthSessionModel.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('Expected a JSON object, got $value');
  }

  @override
  Future<UserModel> getMyProfile() async {
    final response = await _dio.get('/api/v1/me');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<PublicProfileModel> getPublicProfile(int profileId) async {
    final response = await _dio.get('/api/v1/users/$profileId');
    return PublicProfileModel.fromJson(response.data);
  }

  @override
  Future<String> getProfileShareUrl(int profileId) async {
    final response = await _dio.get('/api/v1/users/$profileId/share');
    final data = _asMap(response.data);
    final url = data['url'];
    if (url is! String || url.isEmpty) {
      throw FormatException('Expected profile share URL');
    }
    return url;
  }

  @override
  Future<UserModel> patchMyProfile(PatchProfileBody body) async {
    final response = await _dio.patch('/api/v1/me', data: body.toJson());
    return UserModel.fromJson(response.data);
  }

  @override
  Future<WishlistModel> createWishlist(CreateWishlistBody body) async {
    final response = await _dio.post('/api/v1/wishlists', data: body.toJson());
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<void> deleteBulkWishlistsByIds(List<int> ids) async {
    await _dio.delete('/api/v1/wishlists', data: {'ids': ids});
  }

  @override
  Future<void> deleteWishlistById(int wishlistId) async {
    await _dio.delete('/api/v1/wishlists/$wishlistId');
  }

  @override
  Future<WishlistModel> getMyWishlistById(int wishlistId) async {
    final response = await _dio.get('/api/v1/wishlists/$wishlistId');
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyWishlists() async {
    final response = await _dio.get('/api/v1/wishlists');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<WishlistModel> patchWishlistById(
    int wishlistId,
    PatchWishlistBody body,
  ) async {
    final response = await _dio.patch(
      '/api/v1/wishlists/$wishlistId',
      data: body.toJson(),
    );
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<void> reorderWishlists(ReorderIdsBody body) async {
    await _dio.patch('/api/v1/wishlists', data: body.toJson());
  }

  @override
  Future<WishlistShareModel> shareWishlist(int wishlistId) async {
    final response = await _dio.post('/api/v1/wishlists/$wishlistId/share');
    return WishlistShareModel.fromJson(_asMap(response.data));
  }

  @override
  Future<WishlistModel> getSharedWishlist(String token) async {
    final response = await _dio.get(
      '/api/v1/shared/${Uri.encodeComponent(token)}',
    );
    return WishlistModel.fromJson(_asMap(response.data));
  }

  @override
  Future<WishModel> reserveSharedWish(String token, int wishId) async {
    final response = await _dio.post(_sharedReservationPath(token, wishId));
    return WishModel.fromJson(_asMap(response.data));
  }

  @override
  Future<WishModel> cancelSharedWishReservation(
    String token,
    int wishId,
  ) async {
    final response = await _dio.delete(_sharedReservationPath(token, wishId));
    return WishModel.fromJson(_asMap(response.data));
  }

  String _sharedReservationPath(String token, int wishId) {
    return '/api/v1/shared/${Uri.encodeComponent(token)}/wishes/$wishId/reservation';
  }

  @override
  Future<WishlistModel> addWishlistToFavorites(AddFavoriteBody body) async {
    final response = await _dio.post('/api/v1/favorites', data: body.toJson());
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyFavoriteWishlists() async {
    final response = await _dio.get('/api/v1/favorites');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<void> reorderFavorites(ReorderIdsBody body) async {
    await _dio.patch('/api/v1/favorites', data: body.toJson());
  }

  @override
  Future<void> deleteFavoriteById(int wishlistId) async {
    await _dio.delete('/api/v1/favorites/$wishlistId');
  }

  @override
  Future<WishModel> createWish(CreateWishBody body) async {
    final response = await _dio.post('/api/v1/wishes', data: body.toJson());
    return WishModel.fromJson(response.data);
  }

  @override
  Future<WishModel> duplicateWishById(int wishId) async {
    final response = await _dio.post('/api/v1/wishes/$wishId/duplicate');
    return WishModel.fromJson(response.data);
  }

  @override
  Future<List<WishModel>> getMyWishes({
    String? query,
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get(
      '/api/v1/wishes',
      queryParameters: {
        'mine': 'true',
        if (query != null && query.isNotEmpty) 'query': query,
        'limit': ?limit,
        'offset': ?offset,
      },
    );
    return WishModel.listFromJson(response.data);
  }

  @override
  Future<List<WishModel>> getMyReservations() async {
    final response = await _dio.get('/api/v1/reservations');
    return WishModel.listFromJson(response.data);
  }

  @override
  Future<WishModel> getMyWishById(int wishId) async {
    final response = await _dio.get('/api/v1/wishes/$wishId');
    return WishModel.fromJson(response.data);
  }

  @override
  Future<WishModel> patchWishById(int wishId, PatchWishBody body) async {
    final response = await _dio.patch(
      '/api/v1/wishes/$wishId',
      data: body.toJson(),
    );
    return WishModel.fromJson(response.data);
  }

  @override
  Future<void> deleteBulkWishesByIds(List<int> ids) async {
    await _dio.delete('/api/v1/wishes', data: {'ids': ids});
  }

  @override
  Future<void> deleteWishById(int wishId) async {
    await _dio.delete('/api/v1/wishes/$wishId');
  }

  @override
  Future<WishModel> addWishToWishlist(
    int wishlistId,
    AddWishlistWishBody body,
  ) async {
    final response = await _dio.post(
      '/api/v1/wishlists/$wishlistId/wishes',
      data: body.toJson(),
    );
    return WishModel.fromJson(response.data);
  }

  @override
  Future<void> reorderWishesInWishlist(
    int wishlistId,
    ReorderIdsBody body,
  ) async {
    await _dio.patch(
      '/api/v1/wishlists/$wishlistId/wishes',
      data: body.toJson(),
    );
  }

  @override
  Future<void> removeWishFromWishlist(int wishlistId, int wishId) async {
    await _dio.delete('/api/v1/wishlists/$wishlistId/wishes/$wishId');
  }

  @override
  Future<UserModel> subscribeToProfile(SubscribeUserBody body) async {
    final response = await _dio.post(
      '/api/v1/subscriptions/users',
      data: body.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<WishlistModel> subscribeToWishlist(SubscribeWishlistBody body) async {
    final response = await _dio.post(
      '/api/v1/subscriptions/wishlists',
      data: body.toJson(),
    );
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<UserModel>> getMyProfileSubscriptions() async {
    final response = await _dio.get('/api/v1/subscriptions/users');
    return UserModel.listFromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyWishlistSubscriptions() async {
    final response = await _dio.get('/api/v1/subscriptions/wishlists');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<void> unsubscribeProfile(int userId) async {
    await _dio.delete('/api/v1/subscriptions/users/$userId');
  }

  @override
  Future<void> unsubscribeWishlist(int wishlistId) async {
    await _dio.delete('/api/v1/subscriptions/wishlists/$wishlistId');
  }
}
