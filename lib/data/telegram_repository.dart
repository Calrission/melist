import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';

class RealTelegramRepository implements ITelegramRepository {

  final WebApp _webApp = WebApp();

  @override
  Future<void> initialize() {
    _webApp.init();
    return Future.value();
  }

  @override
  bool get isAvailable {
    return _webApp.initData.isNotEmpty;
  }
}