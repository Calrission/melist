/// Visibility of a wishlist (`wishlist_visibility`).
enum WishlistVisibility {
  public,
  draft;

  static WishlistVisibility fromName(Object? raw) =>
      decodeEnum(WishlistVisibility.values, raw, 'WishlistVisibility');
}

/// Visibility of a wish (`wish_visibility`).
enum WishVisibility {
  public,
  private,
  link;

  static WishVisibility fromName(Object? raw) =>
      decodeEnum(WishVisibility.values, raw, 'WishVisibility');
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

/// Maps a PostgreSQL enum / JSON string onto a Dart enum by [Enum.name].
T decodeEnum<T extends Enum>(List<T> values, Object? raw, String typeName) {
  if (raw is T) {
    return raw;
  }
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
  }
  throw FormatException('Unknown $typeName: $raw');
}
