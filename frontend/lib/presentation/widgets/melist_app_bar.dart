import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';

class MelistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MelistAppBar({super.key, this.title, this.actions, this.onBack});

  static const _topPadding = 8.0;

  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + _topPadding);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _topPadding),
      child: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: onBack ?? context.pop,
            icon: Icon(MelistIcons.back, color: context.palette.subText),
          ),
        ),
        title: title == null
            ? null
            : Text(
                title!,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
        actions: actions == null
            ? null
            : [...actions!, const SizedBox(width: 10)],
      ),
    );
  }
}
