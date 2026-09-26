import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/data/repository/telegram_repository.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class TelegramProvider {
  static SingleChildWidget get provider => Provider(
      create: (ctx) {
        if (kDebugMode) {
          return MockTelegramRepository();
        }

        try {
          WebApp().init();
          return RealTelegramRepository();
        } catch (e) {
          debugPrint('Telegram init failed: $e');
          return UnavailableTelegramRepository();
        }
      }
  );
}
