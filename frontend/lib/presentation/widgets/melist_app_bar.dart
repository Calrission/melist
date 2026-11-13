import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';

class MelistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MelistAppBar({super.key, this.title, this.actions});

  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 56,
      titleSpacing: 6,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: context.pop,
          icon: Icon(MelistIcons.back, color: context.palette.subText),
        ),
      ),
      title: title,
      actions: actions?..add(SizedBox(width: 20)),
    );
  }
}
