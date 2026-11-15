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
    final response = await _dio.get('/api/me');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<PublicProfileModel> getPublicProfile(int profileId) async {
    final response = await _dio.get('/api/users/$profileId');
    return PublicProfileModel.fromJson(response.data);
  }

  @override
  Future<String> getProfileShareUrl(int profileId) async {
    final response = await _dio.get('/api/users/$profileId/share');
    final data = _asMap(response.data);
    final url = data['url'];
    if (url is! String || url.isEmpty) {
      throw FormatException('Expected profile share URL');
    }
    return url;
  }

  @override
  Future<UserModel> patchMyProfile(PatchProfileBody body) async {
    final response = await _dio.patch('/api/me', data: body.toJson());
    return UserModel.fromJson(response.data);
  }

  @override
  Future<WishlistModel> createWishlist(CreateWishlistBody body) async {
    final response = await _dio.post('/api/wishlists', data: body.toJson());
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<void> deleteBulkWishlistsByIds(List<int> ids) async {
    await _dio.delete('/api/wishlists', data: {'ids': ids});
  }

  @override
  Future<void> deleteWishlistById(int wishlistId) async {
    await _dio.delete('/api/wishlists/$wishlistId');
  }

  @override
  Future<WishlistModel> getMyWishlistById(int wishlistId) async {
    final response = await _dio.get('/api/wishlists/$wishlistId');
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyWishlists() async {
    final response = await _dio.get('/api/wishlists');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<WishlistModel> patchWishlistById(
    int wishlistId,
    PatchWishlistBody body,
  ) async {
    final response = await _dio.patch(
      '/api/wishlists/$wishlistId',
      data: body.toJson(),
    );
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<void> reorderWishlists(ReorderIdsBody body) async {
    await _dio.patch('/api/wishlists', data: body.toJson());
  }

  @override
  Future<WishlistShareModel> shareWishlist(int wishlistId) async {
    final response = await _dio.post('/api/wishlists/$wishlistId/share');
    return WishlistShareModel.fromJson(_asMap(response.data));
  }

  @override
  Future<WishlistModel> getSharedWishlist(String token) async {
    final response = await _dio.get(
      '/api/shared/${Uri.encodeComponent(token)}',
    );
    return WishlistModel.fromJson(_asMap(response.data));
  }

  @override
  Future<WishlistModel> addWishlistToFavorites(AddFavoriteBody body) async {
    final response = await _dio.post('/api/favorites', data: body.toJson());
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyFavoriteWishlists() async {
    final response = await _dio.get('/api/favorites');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<void> reorderFavorites(ReorderIdsBody body) async {
    await _dio.patch('/api/favorites', data: body.toJson());
  }

  @override
  Future<void> deleteFavoriteById(int wishlistId) async {
    await _dio.delete('/api/favorites/$wishlistId');
  }

  @override
  Future<WishModel> createWish(CreateWishBody body) async {
    final response = await _dio.post('/api/wishes', data: body.toJson());
    return WishModel.fromJson(response.data);
  }

  @override
  Future<WishModel> duplicateWishById(int wishId) async {
    final response = await _dio.post('/api/wishes/$wishId/duplicate');
    return WishModel.fromJson(response.data);
  }

  @override
  Future<List<WishModel>> getMyWishes({
    String? query,
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get(
      '/api/wishes',
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
  Future<WishModel> getMyWishById(int wishId) async {
    final response = await _dio.get('/api/wishes/$wishId');
    return WishModel.fromJson(response.data);
  }

  @override
  Future<WishModel> patchWishById(int wishId, PatchWishBody body) async {
    final response = await _dio.patch(
      '/api/wishes/$wishId',
      data: body.toJson(),
    );
    return WishModel.fromJson(response.data);
  }

  @override
  Future<void> deleteBulkWishesByIds(List<int> ids) async {
    await _dio.delete('/api/wishes', data: {'ids': ids});
  }

  @override
  Future<void> deleteWishById(int wishId) async {
    await _dio.delete('/api/wishes/$wishId');
  }

  @override
  Future<WishModel> addWishToWishlist(
    int wishlistId,
    AddWishlistWishBody body,
  ) async {
    final response = await _dio.post(
      '/api/wishlists/$wishlistId/wishes',
      data: body.toJson(),
    );
    return WishModel.fromJson(response.data);
  }

  @override
  Future<void> reorderWishesInWishlist(
    int wishlistId,
    ReorderIdsBody body,
  ) async {
    await _dio.patch('/api/wishlists/$wishlistId/wishes', data: body.toJson());
  }

  @override
  Future<void> removeWishFromWishlist(int wishlistId, int wishId) async {
    await _dio.delete('/api/wishlists/$wishlistId/wishes/$wishId');
  }

  @override
  Future<UserModel> subscribeToProfile(SubscribeUserBody body) async {
    final response = await _dio.post(
      '/api/subscriptions/users',
      data: body.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<WishlistModel> subscribeToWishlist(SubscribeWishlistBody body) async {
    final response = await _dio.post(
      '/api/subscriptions/wishlists',
      data: body.toJson(),
    );
    return WishlistModel.fromJson(response.data);
  }

  @override
  Future<List<UserModel>> getMyProfileSubscriptions() async {
    final response = await _dio.get('/api/subscriptions/users');
    return UserModel.listFromJson(response.data);
  }

  @override
  Future<List<WishlistModel>> getMyWishlistSubscriptions() async {
    final response = await _dio.get('/api/subscriptions/wishlists');
    return WishlistModel.listFromJson(response.data);
  }

  @override
  Future<void> unsubscribeProfile(int userId) async {
    await _dio.delete('/api/subscriptions/users/$userId');
  }

  @override
  Future<void> unsubscribeWishlist(int wishlistId) async {
    await _dio.delete('/api/subscriptions/wishlists/$wishlistId');
  }
}
