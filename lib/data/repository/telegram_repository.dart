import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/domain/models/user_data_model.dart';

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

  @override
  UserDataModel getUserData() {
    final user = _webApp.initDataUnsafe.user;
    return UserDataModel(
      id: user?.id,
      firstName: user?.firstName,
      lastName: user?.lastName,
      username: user?.username,
      avatarUrl: user?.photoUrl
    );
  }

  @override
  Brightness getBrightness() {
    return switch(_webApp.colorScheme) {
      WebAppColorScheme.light => Brightness.light,
      WebAppColorScheme.dark => Brightness.dark,
    };
  }
}