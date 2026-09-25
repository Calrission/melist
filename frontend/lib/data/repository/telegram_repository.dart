import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist_core/melist_core.dart';

class RealTelegramRepository implements ITelegramRepository {
  final WebApp _webApp = WebApp();
  final _brightnessController = StreamController<Brightness>.broadcast();

  @override
  Future<void> initialize() {
    _webApp.init();
    _webApp.eventHandler.themeChanged.listen((theme) {
      final (scheme, _) = theme;
      _brightnessController.add(switch (scheme) {
        WebAppColorScheme.light => Brightness.light,
        WebAppColorScheme.dark => Brightness.dark,
      });
    });
    return Future.value();
  }

  @override
  bool get isAvailable {
    return _webApp.initData.isNotEmpty;
  }

  @override
  String get initData => _webApp.initData;

  @override
  UserModel getUserData() {
    final user = _webApp.initDataUnsafe.user;
    return UserModel(
      id: user?.id ?? 0,
      firstName: user?.firstName,
      lastName: user?.lastName,
      username: user?.username,
      avatarUrl: user?.photoUrl,
    );
  }

  @override
  Brightness getBrightness() {
    return switch (_webApp.colorScheme) {
      WebAppColorScheme.light => Brightness.light,
      WebAppColorScheme.dark => Brightness.dark,
    };
  }

  @override
  Stream<Brightness> get onBrightnessChanged => _brightnessController.stream;

  @override
  void dispose() {
    _brightnessController.close();
  }
}
