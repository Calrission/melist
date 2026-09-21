import 'model_codec.dart';

/// Row of `wishlist_subscriptions`.
class WishlistSubscriptionModel {
  const WishlistSubscriptionModel({
    required this.userId,
    required this.wishlistId,
    this.createdAt,
  });

  factory WishlistSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return WishlistSubscriptionModel(
      userId: requireInt(json['userId'], 'userId'),
      wishlistId: requireInt(json['wishlistId'], 'wishlistId'),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
    );
  }

  factory WishlistSubscriptionModel.fromRow(Map<String, dynamic> row) {
    return WishlistSubscriptionModel(
      userId: requireInt(row['user_id'], 'userId'),
      wishlistId: requireInt(row['wishlist_id'], 'wishlistId'),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
    );
  }

  final int userId;
  final int wishlistId;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'userId': userId,
    'wishlistId': wishlistId,
    'createdAt': isoOrNull(createdAt),
  };
}
