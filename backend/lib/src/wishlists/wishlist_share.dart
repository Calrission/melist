import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

final _random = Random.secure();

/// URL-safe token stored in `wishlists.share_token` (7.1).
String generateShareToken() {
  final bytes = Uint8List(9);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = _random.nextInt(256);
  }
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Main Mini App link: `https://t.me/<bot>?startapp=wl_<token>`.
///
/// The `/<shortName>` form opens a named Direct Link Mini App. Without a
/// short name Telegram opens the bot chat instead of the Main Mini App.
String telegramShareUrl({
  required String botUsername,
  required String token,
}) {
  return 'https://t.me/$botUsername?startapp=wl_$token';
}

/// Main Mini App link to a user's public profile.
String telegramProfileUrl({
  required String botUsername,
  required int userId,
}) {
  return 'https://t.me/$botUsername?startapp=profile_$userId';
}

String normalizeShareToken(String raw) {
  var value = raw.trim();
  if (value.startsWith('wl_')) {
    value = value.substring(3);
  }
  return value;
}
