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
    this.copiedFrom,
    this.createdAt,
    this.updatedAt,
  });

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
    'copiedFrom': copiedFrom,
    'createdAt': isoOrNull(createdAt),
    'updatedAt': isoOrNull(updatedAt),
  };
}
