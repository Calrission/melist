import '../enums.dart';
import '../model_codec.dart';

/// Fields of a new wish: `POST /api/v1/wishes` and nested `wish` in
/// `POST /api/v1/wishlists/{id}/wishes`.
class CreateWishBody {
  const CreateWishBody({
    required this.name,
    this.price,
    this.url,
    this.description,
    this.coverUrl,
    this.status,
  });

  factory CreateWishBody.fromJson(Map<String, dynamic> json) {
    return CreateWishBody(
      name: requireString(json['name'], 'name'),
      price: optionalDouble(json['price'], 'price'),
      url: optionalString(json['url']),
      description: optionalString(json['description']),
      coverUrl: optionalString(json['coverUrl']),
      status: optionalEnum(WishStatus.values, json['status'], 'WishStatus'),
    );
  }

  final String name;
  final double? price;
  final String? url;
  final String? description;
  final String? coverUrl;
  final WishStatus? status;

  Map<String, Object?> toJson() => {
    'name': name,
    if (price != null) 'price': price,
    if (url != null) 'url': url,
    if (description != null) 'description': description,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (status != null) 'status': status!.name,
  };
}

/// Body of `PATCH /api/v1/wishes/{id}`.
///
/// [price], [url], [description], [coverUrl] default to [jsonOmit].
/// Pass `null` to clear them.
class PatchWishBody {
  const PatchWishBody({
    this.name,
    this.price = jsonOmit,
    this.url = jsonOmit,
    this.description = jsonOmit,
    this.coverUrl = jsonOmit,
    this.status,
  });

  factory PatchWishBody.fromJson(Map<String, dynamic> json) {
    return PatchWishBody(
      name: optionalString(json['name']),
      price: json.containsKey('price') ? json['price'] : jsonOmit,
      url: json.containsKey('url') ? json['url'] : jsonOmit,
      description: json.containsKey('description')
          ? json['description']
          : jsonOmit,
      coverUrl: json.containsKey('coverUrl') ? json['coverUrl'] : jsonOmit,
      status: optionalEnum(WishStatus.values, json['status'], 'WishStatus'),
    );
  }

  final String? name;
  final Object? price;
  final Object? url;
  final Object? description;
  final Object? coverUrl;
  final WishStatus? status;

  Map<String, Object?> toJson() {
    return {
      if (name != null) 'name': name,
      if (jsonIncluded(price)) 'price': price,
      if (jsonIncluded(url)) 'url': url,
      if (jsonIncluded(description)) 'description': description,
      if (jsonIncluded(coverUrl)) 'coverUrl': coverUrl,
      if (status != null) 'status': status!.name,
    };
  }
}
