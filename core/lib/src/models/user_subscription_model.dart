import 'model_codec.dart';

/// Row of `user_subscriptions` — [followerId] follows [followeeId].
class UserSubscriptionModel {
  const UserSubscriptionModel({
    required this.followerId,
    required this.followeeId,
    this.createdAt,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      followerId: requireInt(json['followerId'], 'followerId'),
      followeeId: requireInt(json['followeeId'], 'followeeId'),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
    );
  }

  factory UserSubscriptionModel.fromRow(Map<String, dynamic> row) {
    return UserSubscriptionModel(
      followerId: requireInt(row['follower_id'], 'followerId'),
      followeeId: requireInt(row['followee_id'], 'followeeId'),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
    );
  }

  final int followerId;
  final int followeeId;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'followerId': followerId,
    'followeeId': followeeId,
    'createdAt': isoOrNull(createdAt),
  };
}
