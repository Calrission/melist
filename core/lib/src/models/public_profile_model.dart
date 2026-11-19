import 'model_codec.dart';
import 'user_model.dart';
import 'wishlist_model.dart';

/// Response of `GET /api/v1/users/{id}`.
class PublicProfileModel {
  const PublicProfileModel({required this.user, this.wishlists = const []});

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      user: UserModel.fromJson(requireMap(json['user'], 'user')),
      wishlists: _wishlistsFrom(json['wishlists']),
    );
  }

  final UserModel user;
  final List<WishlistModel> wishlists;

  Map<String, Object?> toJson() => {
    'user': user.toJson(),
    'wishlists': [for (final wishlist in wishlists) wishlist.toJson()],
  };

  static List<WishlistModel> _wishlistsFrom(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw FormatException('Expected array for wishlists, got $raw');
    }
    return [
      for (final item in raw)
        WishlistModel.fromJson(requireMap(item, 'wishlists')),
    ];
  }
}
