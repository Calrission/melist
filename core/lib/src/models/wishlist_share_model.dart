import 'model_codec.dart';

/// Response of `POST /api/v1/wishlists/{id}/share`.
class WishlistShareModel {
  const WishlistShareModel({required this.shareToken, required this.url});

  factory WishlistShareModel.fromJson(Map<String, dynamic> json) {
    return WishlistShareModel(
      shareToken: requireString(json['shareToken'], 'shareToken'),
      url: requireString(json['url'], 'url'),
    );
  }

  final String shareToken;
  final String url;

  Map<String, Object?> toJson() => {'shareToken': shareToken, 'url': url};
}
