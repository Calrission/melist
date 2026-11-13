import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist_core/melist_core.dart';

import '../router/app_router.dart';

class WishListTile extends StatelessWidget {

  final VoidCallback? onTap;
  final VoidCallback? onTapDelete;
  final bool showEdit;

  /// Non-null turns on the selection checkbox.
  final bool? selected;
  final ValueChanged<bool?>? onSelect;
  final List<Widget> actions;

  final WishlistModel wishlistModel;

  const WishListTile({
    super.key,
    this.onTap,
    this.onTapDelete,
    this.showEdit = true,
    this.selected,
    this.onSelect,
    this.actions = const [],
    required this.wishlistModel
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: (selected != null)
          ? Checkbox(value: selected, onChanged: onSelect)
          : null,
      title: Text(wishlistModel.name),
      subtitle: Text(
        "Кол-во вишей: ${wishlistModel.items.length} | "
        "${wishlistModel.visibility.name} | ${wishlistModel.color}",
      ),

      onTap: onTap,
      trailing: Row(
        spacing: 8,
        mainAxisSize: .min,
        children: [
          ...actions,
          if (showEdit)
            IconButton(
              onPressed: () {
                context.goNamed(
                  wishlistEditGoKey,
                  pathParameters: {'id': wishlistModel.id.toString()},
                );
              },
              icon: Icon(Icons.edit),
            ),
          if (onTapDelete != null)
            IconButton(
              onPressed: onTapDelete,
              icon: Icon(Icons.delete),
            ),
        ],
      ),
    );
  }

}
