import 'package:flutter/material.dart';
import 'package:melist_core/melist_core.dart';

class Palette {
  final Color background;
  final Color text;
  final Color accent;
  final Color textOnAccent;
  final Color hint;

  Palette({
    required this.background, required this.text,
    required this.accent, required this.textOnAccent,
    required this.hint
  });

  factory Palette.light() {
    return Palette(
      background: Colors.white,
      text: Colors.black,
      accent: Color(0xFF3C4FB4),
      textOnAccent: Colors.white,
      hint: Colors.grey,
    );
  }

  factory Palette.dark() {
    return Palette(
      background: Colors.black,
      text: Colors.white,
      accent: Color(0xFF3C4FB4),
      textOnAccent: Colors.white,
      hint: Colors.grey,
    );
  }

  factory Palette.fromUiTheme(UiTheme theme) {
    return switch (theme) {
      UiTheme.light => Palette.light(),
      UiTheme.dark => Palette.dark(),
      UiTheme.system => Palette.light(),
    };
  }

  Palette copyWith({Color? background, Color? text, Color? accent, Color? textOnAccent, Color? hint}) {
    return Palette(
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
    );
  }
}