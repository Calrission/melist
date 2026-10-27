import 'package:flutter/material.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist_core/melist_core.dart';

class ProfileWidget extends StatelessWidget {

  final UserModel userModel;

  const ProfileWidget({
    super.key,
    required this.userModel
  });

  void _changeBirthday(BuildContext context) async {
    final newBirthday = await showDatePicker(
        context: context,
        initialDate: userModel.birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime.now()
    );
    if (newBirthday == null || !context.mounted) {
      return;
    }
    context.guard(() => ProfileController.of(context).updateBirthday(newBirthday));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.of(context);
    final userModel = controller.profile!;
    return Center(
      child: Column(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Text(
              'Hello, ${userModel.username}!',
              style: TextStyle(
                color: context.palette.text,
              ),
            ),
            if (userModel.avatarUrl != null)
              ClipOval(
                child: Image.network(
                  width: 200,
                  userModel.avatarUrl!,
                  errorBuilder: (_, _, _) => const Icon(Icons.person),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(),
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                ),
              ),
            Text(
              'id = ${userModel.id}\n'
              'firstName = ${userModel.firstName}\n'
              'lastName = ${userModel.lastName}\n'
              'avatarUrl = ${userModel.avatarUrl}\n'
              'birthday = ${userModel.birthday?.toIso8601String().substring(0, 10)}\n'
              'theme = ${userModel.theme.name}',
              style: TextStyle(
                color: context.palette.text,
              ),
            ),
            Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _changeBirthday(context),
                  child: Text("Указать дату рождения"),
                ),
                if (userModel.birthday != null)
                  OutlinedButton(
                    onPressed: () => context.guard(controller.clearBirthday),
                    child: Text("Сбросить"),
                  ),
              ],
            ),
            Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                Text("Тема:", style: TextStyle(color: context.palette.text)),
                DropdownButton<UiTheme>(
                  value: userModel.theme,
                  items: [
                    for (final theme in UiTheme.values)
                      DropdownMenuItem(value: theme, child: Text(theme.name)),
                  ],
                  onChanged: (theme) {
                    if (theme == null || theme == userModel.theme) {
                      return;
                    }
                    context.guard(() => controller.updateTheme(theme));
                  },
                ),
              ],
            ),
          ],
      ),
    );
  }
}
