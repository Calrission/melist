import 'enums.dart';
import 'model_codec.dart';

/// Row of `wishes`. Exists independently of any wishlist.
class WishModel {
  const WishModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.price,
    this.url,
    this.description,
    this.coverUrl,
    this.status = WishStatus.free,
    this.wishlists = const [],
    this.copiedFrom,
    this.createdAt,
    this.updatedAt,
  });

  static List<WishModel> listFromJson(Object? data) {
    return (data as List).map((e) => WishModel.fromJson(e)).toList();
  }

  factory WishModel.fromJson(Map<String, dynamic> json) {
    return WishModel(
      id: requireInt(json['id'], 'id'),
      ownerId: requireInt(json['ownerId'], 'ownerId'),
      name: requireString(json['name'], 'name'),
      price: optionalDouble(json['price'], 'price'),
      url: optionalString(json['url']),
      description: optionalString(json['description']),
      coverUrl: optionalString(json['coverUrl']),
      status: json['status'] == null
          ? WishStatus.free
          : WishStatus.fromName(json['status']),
      wishlists: _wishlistsFrom(json['wishlists']),
      copiedFrom: optionalInt(json['copiedFrom'], 'copiedFrom'),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
      updatedAt: optionalDateTime(json['updatedAt'], 'updatedAt'),
    );
  }

  factory WishModel.fromRow(Map<String, dynamic> row) {
    return WishModel(
      id: requireInt(row['id'], 'id'),
      ownerId: requireInt(row['owner_id'], 'ownerId'),
      name: requireString(row['name'], 'name'),
      price: optionalDouble(row['price'], 'price'),
      url: optionalString(row['url']),
      description: optionalString(row['description']),
      coverUrl: optionalString(row['cover_url']),
      status: row['status'] == null
          ? WishStatus.free
          : WishStatus.fromName(row['status']),
      copiedFrom: optionalInt(row['copied_from'], 'copiedFrom'),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
      updatedAt: optionalDateTime(row['updated_at'], 'updatedAt'),
    );
  }

  final int id;
  final int ownerId;
  final String name;
  final double? price;
  final String? url;
  final String? description;
  final String? coverUrl;
  final WishStatus status;

  /// Owner's wishlists that contain this wish. Filled on `GET /api/v1/wishes/{id}`.
  final List<WishWishlistModel> wishlists;
  final int? copiedFrom;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'price': price,
    'url': url,
    'description': description,
    'coverUrl': coverUrl,
    'status': status.name,
    if (wishlists.isNotEmpty)
      'wishlists': [for (final wishlist in wishlists) wishlist.toJson()],
    'copiedFrom': copiedFrom,
    'createdAt': isoOrNull(createdAt),
    'updatedAt': isoOrNull(updatedAt),
  };

  WishModel withWishlists(List<WishWishlistModel> wishlists) {
    return WishModel(
      id: id,
      ownerId: ownerId,
      name: name,
      price: price,
      url: url,
      description: description,
      coverUrl: coverUrl,
      status: status,
      wishlists: wishlists,
      copiedFrom: copiedFrom,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<WishWishlistModel> _wishlistsFrom(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map)
          WishWishlistModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}

/// Wishlist that contains a wish, as returned on the wish card.
class WishWishlistModel {
  const WishWishlistModel({required this.id, required this.name});

  factory WishWishlistModel.fromJson(Map<String, dynamic> json) {
    return WishWishlistModel(
      id: requireInt(json['id'], 'id'),
      name: requireString(json['name'], 'name'),
    );
  }

  factory WishWishlistModel.fromRow(Map<String, dynamic> row) {
    return WishWishlistModel(
      id: requireInt(row['id'], 'id'),
      name: requireString(row['name'], 'name'),
    );
  }

  final int id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};
}
