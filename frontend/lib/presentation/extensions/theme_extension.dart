import 'package:flutter/material.dart';
import 'package:melist/presentation/theme/palette.dart';

class PaletteThemeExtension extends ThemeExtension<PaletteThemeExtension> {

  final Palette palette;

  PaletteThemeExtension({required this.palette});

  @override
  ThemeExtension<PaletteThemeExtension> copyWith({Palette? palette}) {
    return PaletteThemeExtension(palette: palette ?? this.palette);
  }

  @override
  ThemeExtension<PaletteThemeExtension> lerp(
    covariant ThemeExtension<PaletteThemeExtension>? other, double t
  ) {
    if (other is! PaletteThemeExtension) {
      return this;
    }

    return PaletteThemeExtension(palette: palette.lerp(other.palette, t));
  }
}