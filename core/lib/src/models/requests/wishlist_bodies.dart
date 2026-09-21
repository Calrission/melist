import '../enums.dart';
import '../model_codec.dart';
import 'wish_bodies.dart';

/// Body of `POST /api/wishlists`.
class CreateWishlistBody {
  const CreateWishlistBody({
    required this.name,
    this.description,
    this.color,
    this.visibility,
    this.wishIds = const [],
  });

  factory CreateWishlistBody.fromJson(Map<String, dynamic> json) {
    return CreateWishlistBody(
      name: requireString(json['name'], 'name'),
      description: optionalString(json['description']),
      color: optionalString(json['color']),
      visibility: optionalEnum(
        WishlistVisibility.values,
        json['visibility'],
        'WishlistVisibility',
      ),
      wishIds: optionalIntList(json['wishIds'], 'wishIds'),
    );
  }

  final String name;
  final String? description;
  final String? color;
  final WishlistVisibility? visibility;
  final List<int> wishIds;

  Map<String, Object?> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (color != null) 'color': color,
    if (visibility != null) 'visibility': visibility!.name,
    if (wishIds.isNotEmpty) 'wishIds': wishIds,
  };
}

/// Body of `PATCH /api/wishlists/{id}`.
///
/// [description] defaults to [jsonOmit]. Pass `null` to clear.
class PatchWishlistBody {
  const PatchWishlistBody({
    this.name,
    this.description = jsonOmit,
    this.color,
    this.visibility,
  });

  factory PatchWishlistBody.fromJson(Map<String, dynamic> json) {
    return PatchWishlistBody(
      name: optionalString(json['name']),
      description: json.containsKey('description')
          ? json['description']
          : jsonOmit,
      color: optionalString(json['color']),
      visibility: optionalEnum(
        WishlistVisibility.values,
        json['visibility'],
        'WishlistVisibility',
      ),
    );
  }

  final String? name;
  final Object? description;
  final String? color;
  final WishlistVisibility? visibility;

  Map<String, Object?> toJson() {
    return {
      if (name != null) 'name': name,
      if (jsonIncluded(description)) 'description': description,
      if (color != null) 'color': color,
      if (visibility != null) 'visibility': visibility!.name,
    };
  }
}

/// Body of `POST /api/wishlists/{id}/wishes`. Exactly one variant.
class AddWishlistWishBody {
  const AddWishlistWishBody.create(CreateWishBody this.wish)
    : wishId = null,
      copyFromWishId = null;

  const AddWishlistWishBody.attach(int this.wishId)
    : wish = null,
      copyFromWishId = null;

  const AddWishlistWishBody.copy(int this.copyFromWishId)
    : wish = null,
      wishId = null;

  factory AddWishlistWishBody.fromJson(Map<String, dynamic> json) {
    final variants = [
      if (json['wish'] != null) 'wish',
      if (json['wishId'] != null) 'wishId',
      if (json['copyFromWishId'] != null) 'copyFromWishId',
    ];
    if (variants.length != 1) {
      throw const FormatException(
        'Provide exactly one of wish, wishId or copyFromWishId',
      );
    }
    if (json['wish'] != null) {
      return AddWishlistWishBody.create(
        CreateWishBody.fromJson(requireMap(json['wish'], 'wish')),
      );
    }
    if (json['wishId'] != null) {
      return AddWishlistWishBody.attach(requireInt(json['wishId'], 'wishId'));
    }
    return AddWishlistWishBody.copy(
      requireInt(json['copyFromWishId'], 'copyFromWishId'),
    );
  }

  final CreateWishBody? wish;
  final int? wishId;
  final int? copyFromWishId;

  Map<String, Object?> toJson() => {
    if (wish != null) 'wish': wish!.toJson(),
    if (wishId != null) 'wishId': wishId,
    if (copyFromWishId != null) 'copyFromWishId': copyFromWishId,
  };
}

/// `{ "order": [id, …] }` for `PATCH /api/wishlists`,
/// `PATCH /api/wishlists/{id}/wishes`, `PATCH /api/favorites`.
class ReorderIdsBody {
  const ReorderIdsBody({required this.order});

  factory ReorderIdsBody.fromJson(Map<String, dynamic> json) {
    return ReorderIdsBody(order: requireIntList(json['order'], 'order'));
  }

  final List<int> order;

  Map<String, Object?> toJson() => {'order': order};
}
