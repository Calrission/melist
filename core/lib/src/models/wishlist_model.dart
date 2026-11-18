import 'enums.dart';
import 'model_codec.dart';
import 'wish_model.dart';

/// Row of `wishlists`. [items] is filled for the owner's list and the card.
class WishlistModel {
  const WishlistModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.visibility = WishlistVisibility.draft,
    this.position = 0,
    this.shareToken,
    this.ownerNickname,
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
      visibility: json['visibility'] == null
          ? WishlistVisibility.draft
          : WishlistVisibility.fromName(json['visibility']),
      position: optionalInt(json['position'], 'position') ?? 0,
      shareToken: optionalString(json['shareToken']),
      ownerNickname: optionalString(json['ownerNickname']),
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
      visibility: row['visibility'] == null
          ? WishlistVisibility.draft
          : WishlistVisibility.fromName(row['visibility']),
      position: optionalInt(row['position'], 'position') ?? 0,
      shareToken: optionalString(row['share_token']),
      ownerNickname: optionalString(row['owner_nickname']),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
      updatedAt: optionalDateTime(row['updated_at'], 'updatedAt'),
    );
  }

  final int id;
  final int ownerId;
  final String name;
  final String? description;
  final WishlistVisibility visibility;
  final int position;
  final String? shareToken;
  final String? ownerNickname;
  final List<WishModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WishlistModel copyWith({
    List<WishModel>? items,
    String? ownerNickname,
    String? shareToken,
  }) {
    return WishlistModel(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      visibility: visibility,
      position: position,
      shareToken: shareToken ?? this.shareToken,
      ownerNickname: ownerNickname ?? this.ownerNickname,
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
    'visibility': visibility.name,
    'position': position,
    'shareToken': shareToken,
    if (ownerNickname != null) 'ownerNickname': ownerNickname,
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
