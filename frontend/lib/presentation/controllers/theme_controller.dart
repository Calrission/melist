import 'package:flutter/material.dart';
import 'package:melist_core/melist_core.dart';

class ThemeController extends ChangeNotifier {
  UiTheme _profileUiTheme = UiTheme.system;
  UiTheme get profileUiTheme => _profileUiTheme;

  UiTheme _telegramUiTheme = UiTheme.light;
  UiTheme get telegramUiTheme => _telegramUiTheme;

  UiTheme get theme {
    if (profileUiTheme != UiTheme.system) {
      return profileUiTheme;
    }
    if (telegramUiTheme != UiTheme.system) {
      return telegramUiTheme;
    }
    return UiTheme.light;
  }

  void applyFromProfile(UiTheme profileTheme) {
    _profileUiTheme = profileTheme;
    notifyListeners();
  }

  void applyFromTelegram(UiTheme telegramTheme) {
    _telegramUiTheme = telegramTheme;
    notifyListeners();
  }
}