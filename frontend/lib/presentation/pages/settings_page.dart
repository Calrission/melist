import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/labeled_bottom_sheet_selector.dart';
import 'package:melist/presentation/widgets/labeled_text_field.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _themes = [UiTheme.system, UiTheme.light, UiTheme.dark];

  final _nicknameController = TextEditingController();
  var _nicknameInitialized = false;
  var _isSaving = false;

  static String _themeLabel(UiTheme theme) => switch (theme) {
    UiTheme.system => "Как в Telegram",
    UiTheme.light => "Светлая",
    UiTheme.dark => "Тёмная",
  };

  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      final profileController = context.read<ProfileController>();
      if (profileController.profile == null &&
          profileController.state == ControllerState.init) {
        profileController.loadProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<ProfileController>().profile;
    if (!_nicknameInitialized && profile != null) {
      _nicknameController.text = profile.displayName;
      _nicknameInitialized = true;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() => _isSaving = true);
    final saved = await context.guard(
      () => context.read<ProfileController>().updateNickname(
        _nicknameController.text,
      ),
      success: "Имя сохранено",
    );
    if (!mounted) return;
    if (saved) {
      context.pop();
    } else {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final selectedTheme =
        profile?.theme ?? context.watch<ThemeController>().profileUiTheme;

    return Scaffold(
      appBar: const MelistAppBar(title: "Настройки"),
      body: Padding(
        padding: const EdgeInsets.all(horPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledTextField(
                      label: "Имя",
                      hint: "Введите имя",
                      controller: _nicknameController,
                    ),
                    const SizedBox(height: singleSep),
                    LabeledBottomSheetSelector<UiTheme>(
                      label: "Тема оформления",
                      value: selectedTheme,
                      options: _themes,
                      optionLabel: _themeLabel,
                      onChanged: (theme) {
                        if (theme == selectedTheme) return;
                        context.guard(
                          () => context.read<ProfileController>().updateTheme(
                            theme,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: singleSep),
            FilledButton(
              onPressed: _isSaving ? null : _saveNickname,
              child: Text(_isSaving ? "Сохранение..." : "Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}
