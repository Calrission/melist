import 'package:material_ui/material_ui.dart';
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
    final price = wishModel.price == null ? '—' : "${wishModel.price} ₽";
    return ListTile(
      title: Text(wishModel.name),
      leading: (selected != null)
          ? Checkbox(value: selected, onChanged: onSelect)
          : (wishModel.coverUrl != null && wishModel.coverUrl!.isNotEmpty)
              ? Image.network(
                  wishModel.coverUrl!,
                  width: 48,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                )
              : null,
      subtitle: Text(
        "$price | ${wishModel.status.name}"
        "${wishModel.copiedFrom != null ? ' | копия #${wishModel.copiedFrom}' : ''}",
      ),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          ...actions,
          if (onTapDelete != null)
            IconButton(
              onPressed: onTapDelete,
              icon: Icon(Icons.delete)
            )
        ],
      ),
      onTap: onTap
    );
  }
}
