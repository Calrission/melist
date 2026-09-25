import 'dart:async';

import 'package:flutter/foundation.dart';
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
    create: (ctx) {
      final telegram = ctx.read<ITelegramRepository>();
      final theme = ctx.read<ThemeController>();

      return telegram.onBrightnessChanged
        .map(_brightnessToUiTheme)
        .listen(theme.applyFromTelegram);
    },
    dispose: (_, sub) => sub.cancel(),
  );
}