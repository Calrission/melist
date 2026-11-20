import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

String _formatPrice(double price) {
  final value = price == price.truncateToDouble()
      ? price.toInt().toString()
      : price.toString();
  final decimalIndex = value.indexOf('.');
  final integerPart = decimalIndex == -1
      ? value
      : value.substring(0, decimalIndex);
  final isNegative = integerPart.startsWith('-');
  final digits = isNegative ? integerPart.substring(1) : integerPart;
  final grouped = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      grouped.write(' ');
    }
    grouped.write(digits[index]);
  }

  return '${isNegative ? '-' : ''}$grouped'
      '${decimalIndex == -1 ? '' : value.substring(decimalIndex)}';
}

/// Reserved by somebody other than the viewer.
bool wishIsTakenBySomeoneElse(WishModel wish) {
  return wish.status == WishStatus.reserved && !wish.reservedByMe;
}

/// Keeps the current order, then appends wishes taken by someone else.
List<WishModel> wishesWithTakenLast(List<WishModel> wishes) {
  final open = <WishModel>[];
  final taken = <WishModel>[];
  for (final wish in wishes) {
    if (wishIsTakenBySomeoneElse(wish)) {
      taken.add(wish);
    } else {
      open.add(wish);
    }
  }
  return [...open, ...taken];
}

const ColorFilter wishTakenGrayscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

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
    final taken = wishIsTakenBySomeoneElse(wishModel);
    final textColor = taken ? palette.inactive : palette.accent;
    final descriptionColor = taken ? palette.inactive : palette.text;
    final coverUrl = wishModel.coverUrl;
    final description = wishModel.description?.trim();
    final price = wishModel.price == null
        ? "0 ₽"
        : "${_formatPrice(wishModel.price!)} ₽";
    final radius = BorderRadius.circular(borderRadius);
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: 80,
        height: 80,
        child: coverUrl == null || coverUrl.isEmpty
            ? ColoredBox(
                color: palette.subText.withValues(alpha: 0.12),
                child: Icon(Icons.image, color: palette.subText),
              )
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: palette.subText.withValues(alpha: 0.12),
                  child: Icon(Icons.broken_image, color: palette.subText),
                ),
              ),
      ),
    );

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
                        if (taken)
                          ColorFiltered(
                            colorFilter: wishTakenGrayscale,
                            child: cover,
                          )
                        else
                          cover,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 5,
                            children: [
                              Text(
                                wishModel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                description ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: descriptionColor,
                                ),
                              ),
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 33,
                          height: 20,
                          child: taken
                              ? Center(
                                  child: Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: palette.inactive,
                                  ),
                                )
                              : null,
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
