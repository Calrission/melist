import 'package:get_it/get_it.dart';
import 'package:melist/di/telegram_module.dart';

final getIt = GetIt.instance;

Future<void> setup({required bool isDebug}) async {
  await initTelegramModule(getIt, isDebug: isDebug);
}