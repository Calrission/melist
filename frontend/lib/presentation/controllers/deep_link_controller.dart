import 'package:melist/domain/interfaces/i_telegram_repository.dart';

/// Hands out the Telegram Mini App `startapp` launch parameter once.
class DeepLinkController {
  DeepLinkController({required this._telegram});

  final ITelegramRepository _telegram;
  bool _consumed = false;

  String? consumeStartParam() {
    if (_consumed) {
      return null;
    }
    _consumed = true;
    return _telegram.startParam;
  }
}
