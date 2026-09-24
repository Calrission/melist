import 'package:get_it/get_it.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';

/// Silent refresh, then Telegram login, then debug Bearer if allowed.
Future<void> restoreAuthSession(GetIt getIt, {required bool isDebug}) async {
  final initData = getIt.isRegistered<ITelegramRepository>()
      ? getIt<ITelegramRepository>().initData
      : '';
  await getIt<IAuthRepository>().restoreSession(
    initData: initData,
    allowDebug: isDebug,
  );
}
