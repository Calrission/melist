import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

class Palette {
  final UiTheme uiTheme;
  final Color background;
  final Color text;
  final Color subText;
  final Color accent;
  final Color textOnAccent;
  final Color hint;
  final Color container;

  Palette({
    required this.background, required this.text,
    required this.accent, required this.textOnAccent,
    required this.container, required this.subText,
    required this.hint, required this.uiTheme
  });

  factory Palette.light() {
    return Palette(
      background: Colors.white,
      text: Colors.black,
      subText: Color(0xFF939396),
      accent: Color(0xFFFD92C0),
      textOnAccent: Colors.white,
      container: Color(0xFFF9F9F9),
      hint: Colors.grey,
        uiTheme: UiTheme.light
    );
  }

  factory Palette.dark() {
    return Palette(
      background: Colors.black,
      text: Colors.white,
      subText: Color(0xFF939396),
      accent: Color(0xFFFD92C0),
      textOnAccent: Colors.white,
      container: Color(0xFFF9F9F9),
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

  Palette copyWith({Color? background, Color? text, Color? accent, Color? textOnAccent, Color? hint, Color? container, Color? subText, UiTheme? uiTheme}) {
    return Palette(
      uiTheme: uiTheme ?? this.uiTheme,
      background: background ?? this.background,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      hint: hint ?? this.hint,
      container: container ?? this.container,
      subText: subText ?? this.subText,
    );
  }

  Palette lerp(Palette other, double t) {
    return Palette(
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      subText: Color.lerp(subText, other.subText, t)!,
      uiTheme: uiTheme,
      container: Color.lerp(container, other.container, t)!,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: container,
          foregroundColor: text,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}