import 'package:get_it/get_it.dart';
import 'package:melist/di/auth_module.dart';
import 'package:melist/di/config_module.dart';
import 'package:melist/di/dio_module.dart';
import 'package:melist/di/telegram_module.dart';

final getIt = GetIt.instance;

Future<void> setup({required bool isDebug}) async {
  await initConfigModule(getIt);
  await initTelegramModule(getIt, isDebug: isDebug);
  await initDioModule(getIt);
  await restoreAuthSession(getIt, isDebug: isDebug);
}
