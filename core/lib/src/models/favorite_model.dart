import 'model_codec.dart';

/// Row of `favorites` — a wishlist saved by a user.
class FavoriteModel {
  const FavoriteModel({
    required this.userId,
    required this.wishlistId,
    this.position = 0,
    this.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      userId: requireInt(json['userId'], 'userId'),
      wishlistId: requireInt(json['wishlistId'], 'wishlistId'),
      position: optionalInt(json['position'], 'position') ?? 0,
      addedAt: optionalDateTime(json['addedAt'], 'addedAt'),
    );
  }

  factory FavoriteModel.fromRow(Map<String, dynamic> row) {
    return FavoriteModel(
      userId: requireInt(row['user_id'], 'userId'),
      wishlistId: requireInt(row['wishlist_id'], 'wishlistId'),
      position: optionalInt(row['position'], 'position') ?? 0,
      addedAt: optionalDateTime(row['added_at'], 'addedAt'),
    );
  }

  final int userId;
  final int wishlistId;
  final int position;
  final DateTime? addedAt;

  Map<String, Object?> toJson() => {
        'userId': userId,
        'wishlistId': wishlistId,
        'position': position,
        'addedAt': isoOrNull(addedAt),
      };
}
