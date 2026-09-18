import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/data/telegram_repository.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';


Future<void> initTelegramModule(GetIt getIt, {required bool isDebug}) async {
  if (isDebug) {
    getIt.registerLazySingleton<ITelegramRepository>(() => MockTelegramRepository());
    return;
  }

  try {
    WebApp().init();
    getIt.registerLazySingleton<ITelegramRepository>(() => RealTelegramRepository());
  } catch (e) {
    debugPrint('Telegram init failed: $e');
  }
}