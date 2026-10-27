import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/domain/share_token.dart';

/// Hands out the `startapp=wl_<token>` launch parameter exactly once.
class DeepLinkController {
  DeepLinkController({required this._telegram});

  final ITelegramRepository _telegram;
  bool _consumed = false;

  String? consumeSharedToken() {
    if (_consumed) {
      return null;
    }
    _consumed = true;
    final raw = _telegram.startParam;
    if (raw == null || !raw.startsWith('wl_')) {
      return null;
    }
    return parseShareToken(raw);
  }
}
