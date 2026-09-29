import 'model_codec.dart';

/// Visibility of a wishlist (`wishlist_visibility`).
enum WishlistVisibility {
  public,
  draft,
  link;

  static WishlistVisibility fromName(Object? raw) =>
    decodeEnum(WishlistVisibility.values, raw, 'WishlistVisibility');

  static WishlistVisibility fromBool(bool isPublic) => (isPublic)
    ? WishlistVisibility.public
    : WishlistVisibility.draft;
}

/// Status of a wish (`wish_status`).
enum WishStatus {
  draft,
  free,
  reserved;

  static WishStatus fromName(Object? raw) =>
      decodeEnum(WishStatus.values, raw, 'WishStatus');
}

/// UI theme preference (`ui_theme`).
enum UiTheme {
  system,
  light,
  dark;

  static UiTheme fromName(Object? raw) =>
      decodeEnum(UiTheme.values, raw, 'UiTheme');
}

/// How premium access was granted (`entitlement_source`).
enum EntitlementSource {
  ad,
  donation;

  static EntitlementSource fromName(Object? raw) =>
      decodeEnum(EntitlementSource.values, raw, 'EntitlementSource');
}

/// Payment state of a Stars donation (`donations.status`).
enum DonationStatus {
  pending,
  paid,
  refunded;

  static DonationStatus fromName(Object? raw) =>
      decodeEnum(DonationStatus.values, raw, 'DonationStatus');
}
