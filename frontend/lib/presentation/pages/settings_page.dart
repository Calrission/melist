import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/widgets/labeled_bottom_sheet_selector.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _themes = [UiTheme.system, UiTheme.light, UiTheme.dark];

  static String _themeLabel(UiTheme theme) => switch (theme) {
    UiTheme.system => "Как в Telegram",
    UiTheme.light => "Светлая",
    UiTheme.dark => "Тёмная",
  };

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final selectedTheme =
        profile?.theme ?? context.watch<ThemeController>().profileUiTheme;

    return Scaffold(
      appBar: const MelistAppBar(title: "Настройки"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LabeledBottomSheetSelector<UiTheme>(
          label: "Тема оформления",
          value: selectedTheme,
          options: _themes,
          optionLabel: _themeLabel,
          onChanged: (theme) {
            if (theme == selectedTheme) return;
            context.guard(
              () => context.read<ProfileController>().updateTheme(theme),
            );
          },
        ),
      ),
    );
  }
}
