import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

UiTheme _brightnessToUiTheme(Brightness brightness) {
  return switch (brightness) {
    Brightness.light => UiTheme.light,
    Brightness.dark => UiTheme.dark,
  };
}

class TelegramThemeProvider {
  static SingleChildWidget get provider => Provider<StreamSubscription<UiTheme>>(
    lazy: false,
    create: (ctx) {
      final telegram = ctx.read<ITelegramRepository>();
      final theme = ctx.read<ThemeController>();
      final subscription = telegram.onBrightnessChanged
          .map(_brightnessToUiTheme)
          .listen(theme.applyFromTelegram);
      telegram.initialize();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ctx.mounted) {
          return;
        }
        theme.applyFromTelegram(
          _brightnessToUiTheme(telegram.getBrightness()),
        );
      });
      return subscription;
    },
    dispose: (_, sub) => sub.cancel(),
  );
}