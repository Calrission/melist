import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/share_dialog.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class ProfileWidget extends StatelessWidget {
  final UserModel userModel;
  final bool allowBirthdayEdit;

  const ProfileWidget({
    super.key,
    required this.userModel,
    this.allowBirthdayEdit = true,
  });

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

  Future<void> _shareProfile(BuildContext context) async {
    late final String shareUrl;
    try {
      shareUrl = await context.read<IProfileRepository>().getProfileShareUrl(
        userModel.id,
      );
    } on Object catch (error) {
      if (context.mounted) {
        context.showError(error);
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ShareDialog(
        title: "Ссылка на профиль",
        url: shareUrl,
        telegramText: "Мой профиль",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: verySmallSep),
                    Icon(MelistIcons.share, color: context.palette.text),
                  ],
                ),
              ),
            ),
            if (allowBirthdayEdit)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TextButton(
                  onPressed: () => _changeBirthday(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    disabledForegroundColor: context.palette.accent,
                    foregroundColor: context.palette.accent,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text("День рождения: $birthdayText"),
                ),
              )
            else
              Text("День рождения: $birthdayText", style: TextStyle(
                color: context.palette.accent,
                fontWeight: FontWeight.bold
              )),
          ],
        ),
      ],
    );
  }
}
