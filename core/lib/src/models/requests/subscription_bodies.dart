import '../model_codec.dart';

/// Body of `POST /api/v1/subscriptions/wishlists`.
class SubscribeWishlistBody {
  const SubscribeWishlistBody({required this.wishlistId});

  factory SubscribeWishlistBody.fromJson(Map<String, dynamic> json) {
    return SubscribeWishlistBody(
      wishlistId: requireInt(json['wishlistId'], 'wishlistId'),
    );
  }

  final int wishlistId;

  Map<String, Object?> toJson() => {'wishlistId': wishlistId};
}

/// Body of `POST /api/v1/subscriptions/users`.
class SubscribeUserBody {
  const SubscribeUserBody({required this.userId});

  factory SubscribeUserBody.fromJson(Map<String, dynamic> json) {
    return SubscribeUserBody(userId: requireInt(json['userId'], 'userId'));
  }

  final int userId;

  Map<String, Object?> toJson() => {'userId': userId};
}
