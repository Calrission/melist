/// Extracts a share token from a raw token, `wl_<token>` or a Mini App link
/// with `startapp=wl_<token>`.
String? parseShareToken(String raw) {
  var value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(value);
  final startApp = uri?.queryParameters['startapp'];
  if (startApp != null && startApp.isNotEmpty) {
    value = startApp;
  }
  if (value.startsWith('wl_')) {
    value = value.substring(3);
  }
  return value.isEmpty ? null : value;
}
