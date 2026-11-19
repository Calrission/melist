import '../model_codec.dart';

/// Body of `POST /api/v1/favorites`.
class AddFavoriteBody {
  const AddFavoriteBody({required this.shareToken});

  factory AddFavoriteBody.fromJson(Map<String, dynamic> json) {
    return AddFavoriteBody(
      shareToken: requireString(json['shareToken'], 'shareToken'),
    );
  }

  final String shareToken;

  Map<String, Object?> toJson() => {'shareToken': shareToken};
}
