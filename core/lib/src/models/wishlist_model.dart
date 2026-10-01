import 'enums.dart';
import 'model_codec.dart';
import 'wish_model.dart';

/// Row of `wishlists`. [items] is filled for the owner's list and the card.
class WishlistModel {
  const WishlistModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.color,
    this.description,
    this.visibility = WishlistVisibility.draft,
    this.position = 0,
    this.shareToken,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  static List<WishlistModel> listFromJson(Object? data) {
    return (data as List).map((e) => WishlistModel.fromJson(e)).toList();
  }

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: requireInt(json['id'], 'id'),
      ownerId: requireInt(json['ownerId'], 'ownerId'),
      name: requireString(json['name'], 'name'),
      description: optionalString(json['description']),
      color: requireString(json['color'], 'color'),
      visibility: json['visibility'] == null
          ? WishlistVisibility.draft
          : WishlistVisibility.fromName(json['visibility']),
      position: optionalInt(json['position'], 'position') ?? 0,
      shareToken: optionalString(json['shareToken']),
      items: _itemsFrom(json['items']),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
      updatedAt: optionalDateTime(json['updatedAt'], 'updatedAt'),
    );
  }

  factory WishlistModel.fromRow(Map<String, dynamic> row) {
    return WishlistModel(
      id: requireInt(row['id'], 'id'),
      ownerId: requireInt(row['owner_id'], 'ownerId'),
      name: requireString(row['name'], 'name'),
      description: optionalString(row['description']),
      color: requireString(row['color'], 'color'),
      visibility: row['visibility'] == null
          ? WishlistVisibility.draft
          : WishlistVisibility.fromName(row['visibility']),
      position: optionalInt(row['position'], 'position') ?? 0,
      shareToken: optionalString(row['share_token']),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
      updatedAt: optionalDateTime(row['updated_at'], 'updatedAt'),
    );
  }

  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final String color;
  final WishlistVisibility visibility;
  final int position;
  final String? shareToken;
  final List<WishModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WishlistModel copyWith({List<WishModel>? items}) {
    return WishlistModel(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      color: color,
      visibility: visibility,
      position: position,
      shareToken: shareToken,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'color': color,
    'visibility': visibility.name,
    'position': position,
    'shareToken': shareToken,
    'items': [for (final item in items) item.toJson()],
    'createdAt': isoOrNull(createdAt),
    'updatedAt': isoOrNull(updatedAt),
  };

  static List<WishModel> _itemsFrom(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) WishModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
