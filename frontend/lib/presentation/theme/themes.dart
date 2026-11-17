import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/theme/palette.dart';

ButtonStyle getClassicFilledButtonStyle(Palette palette) => FilledButton.styleFrom(
  alignment: Alignment.center,
  minimumSize: const Size(double.infinity, 44),
  maximumSize: null,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius)
  ),
  backgroundColor: palette.accent,
  foregroundColor: palette.textOnAccent,
);

ButtonStyle getMenuItemFilledButtonStyle(Palette palette) => FilledButton.styleFrom(
  backgroundColor: palette.container,
  foregroundColor: palette.text,
  minimumSize: const Size(double.infinity, 50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius)
  ),
  alignment: Alignment.centerLeft,
  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
);