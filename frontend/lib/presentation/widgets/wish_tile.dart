import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

class WishTile extends StatelessWidget {
  final WishModel wishModel;
  final VoidCallback? onTapDelete;
  final VoidCallback? onTap;

  /// Non-null turns on the selection checkbox.
  final bool? selected;
  final ValueChanged<bool?>? onSelect;
  final List<Widget> actions;

  const WishTile({
    super.key,
    required this.wishModel,
    this.onTapDelete,
    this.onTap,
    this.selected,
    this.onSelect,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final coverUrl = wishModel.coverUrl;
    final description = wishModel.description?.trim();
    final price = wishModel.price == null ? "— ₽" : "${wishModel.price} ₽";
    final radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Ink(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected == true
                          ? palette.accent.withValues(alpha: 0.12)
                          : palette.container,
                      borderRadius: radius,
                      border: Border.all(
                        color: selected == true
                            ? palette.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: .start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: SizedBox(
                            width: 62,
                            height: 62,
                            child: coverUrl == null || coverUrl.isEmpty
                                ? ColoredBox(
                                    color: palette.subText.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      color: palette.subText,
                                    ),
                                  )
                                : Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => ColoredBox(
                                      color: palette.subText.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: palette.subText,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 5,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      wishModel.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    MelistIcons.link,
                                    size: 20,
                                    color: (wishModel.url != null)
                                        ? context.palette.accent
                                        : context.palette.subText,
                                  ),
                                ],
                              ),
                              Text(
                                description ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: palette.text,
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (onTapDelete != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Material(
                  color: palette.container,
                  borderRadius: radius,
                  child: InkWell(
                    onTap: onTapDelete,
                    borderRadius: radius,
                    child: Center(
                      child: Icon(MelistIcons.trash, color: palette.text),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
