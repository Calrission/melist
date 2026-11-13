import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/share_dialog.dart';
import 'package:melist_core/melist_core.dart';

class ProfileWidget extends StatelessWidget {
  final UserModel userModel;

  const ProfileWidget({super.key, required this.userModel});

  void _changeBirthday(BuildContext context) async {
    final newBirthday = await showDatePicker(
      context: context,
      initialDate: userModel.birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (newBirthday == null || !context.mounted) {
      return;
    }
    context.guard(
      () => ProfileController.of(context).updateBirthday(newBirthday),
    );
  }

  void _shareProfile(BuildContext context) {
    final url = Uri.base.resolve('/users/${userModel.id}').toString();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ShareDialog(
        title: "Ссылка на профиль",
        url: url,
        telegramText: "Мой профиль",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.of(context);
    final userModel = controller.profile!;
    final birthday = userModel.birthday;
    final birthdayText = birthday == null
        ? "Не указан"
        : '${birthday.day.toString().padLeft(2, '0')}.'
              '${birthday.month.toString().padLeft(2, '0')}.'
              '${birthday.year.toString().padLeft(4, '0')}';
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 90,
            height: 90,
            child:
                userModel.avatarUrl != null && userModel.avatarUrl!.isNotEmpty
                ? Image.network(
                    userModel.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: context.palette.subText.withValues(alpha: 0.2),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : ColoredBox(
                            color: context.palette.subText.withValues(
                              alpha: 0.2,
                            ),
                          ),
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  )
                : ColoredBox(
                    color: context.palette.subText.withValues(alpha: 0.2),
                  ),
          ),
        ),
        SizedBox(width: bigSep),
        Column(
          crossAxisAlignment: .start,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => _shareProfile(context),
                child: Row(
                  children: [
                    Text(
                      userModel.lastNameFirstName,
                      style: TextStyle(
                        color: context.palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: verySmallSep),
                    Icon(MelistIcons.share, color: context.palette.text),
                  ],
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                onPressed: () => _changeBirthday(context),
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text("День рождения: $birthdayText"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
