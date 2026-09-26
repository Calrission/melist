import 'package:flutter/material.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist_core/melist_core.dart';

class Palette {
  final UiTheme uiTheme;
  final Color background;
  final Color text;
  final Color accent;
  final Color textOnAccent;
  final Color hint;

  Palette({
    required this.background, required this.text,
    required this.accent, required this.textOnAccent,
    required this.hint, required this.uiTheme
  });

  factory Palette.light() {
    return Palette(
      background: Colors.white,
      text: Colors.black,
      accent: Color(0xFF3C4FB4),
      textOnAccent: Colors.white,
      hint: Colors.grey,
        uiTheme: UiTheme.light
    );
  }

  factory Palette.dark() {
    return Palette(
      background: Colors.black,
      text: Colors.white,
      accent: Color(0xFF3C4FB4),
      textOnAccent: Colors.white,
      hint: Colors.grey,
        uiTheme: UiTheme.dark
    );
  }

  factory Palette.fromUiTheme(UiTheme theme) {
    return switch (theme) {
      UiTheme.light => Palette.light(),
      UiTheme.dark => Palette.dark(),
      UiTheme.system => Palette.light(),
    };
  }

  Palette copyWith({Color? background, Color? text, Color? accent, Color? textOnAccent, Color? hint, UiTheme? uiTheme}) {
    return Palette(
      uiTheme: uiTheme ?? this.uiTheme,
      background: background ?? this.background,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      hint: hint ?? this.hint,
    );
  }

  Palette lerp(Palette other, double t) {
    return Palette(
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      uiTheme: uiTheme,
    );
  }

  ThemeData get themeData {
    final brightness = uiTheme == UiTheme.light ? Brightness.light : Brightness.dark;
    return ThemeData(
      scaffoldBackgroundColor: background,
      brightness: brightness,
      textTheme: TextTheme().apply(
        bodyColor: text,
        displayColor: text,
      ),
      extensions: [
        PaletteThemeExtension(palette: this),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: accent,
        onPrimary: textOnAccent,
        secondary: accent,
        onSecondary: textOnAccent,
      ),
    );
  }
}