import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/theme/palette.dart';

ButtonStyle getClassicFilledButtonStyle(Palette palette) =>
    FilledButton.styleFrom(
      alignment: Alignment.center,
      minimumSize: const Size(double.infinity, 44),
      maximumSize: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: palette.accent,
      foregroundColor: palette.textOnAccent,
    );

ButtonStyle getInactiveFilledButtonStyle(Palette palette) =>
    FilledButton.styleFrom(
      alignment: Alignment.center,
      minimumSize: const Size(double.infinity, 44),
      maximumSize: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: palette.inactive,
      foregroundColor: palette.textOnAccent,
      disabledBackgroundColor: palette.inactive,
      disabledForegroundColor: palette.textOnAccent,
    );

ButtonStyle getOutlinedActionButtonStyle(Palette palette) =>
    OutlinedButton.styleFrom(
      alignment: Alignment.center,
      minimumSize: const Size(double.infinity, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      foregroundColor: palette.accent,
      side: BorderSide(color: palette.accent),
    );

ButtonStyle getMenuItemFilledButtonStyle(Palette palette) =>
    FilledButton.styleFrom(
      backgroundColor: palette.container,
      foregroundColor: palette.text,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
