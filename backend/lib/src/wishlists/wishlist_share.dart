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

/// Mini App deep link from a share token: `startapp=wl_<token>`.
String telegramShareUrl({
  required String botUsername,
  required String token,
}) {
  return 'https://t.me/$botUsername/app?startapp=wl_$token';
}

String normalizeShareToken(String raw) {
  var value = raw.trim();
  if (value.startsWith('wl_')) {
    value = value.substring(3);
  }
  return value;
}
