import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/add_elem_list_button.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/melist_reorderable_list_view.dart';
import 'package:melist/presentation/widgets/wishlist_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishlistListPage extends StatefulWidget {
  const WishlistListPage({super.key});

  @override
  State<WishlistListPage> createState() => _WishlistListPageState();
}

class _WishlistListPageState extends State<WishlistListPage> {
  Future<void> _confirmDeleteSelected(WishlistListController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text("Вы уверены, что хотите удалить выбранные вишлисты?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("Нет"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("Да"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await context.guard(controller.deleteSelected, success: "Удалено");
  }

  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      final controller = context.read<WishlistListController>();
      if (controller.state == ControllerState.init) {
        controller.loadMyWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistListController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: controller.selectionMode
            ? "Удаление вишлистов"
            : "Список вишлистов",
        actions: [
          IconButton(
            icon: Icon(
              MelistIcons.trash,
              color: controller.selectedIds.isNotEmpty
                  ? context.palette.accent
                  : controller.selectionMode
                  ? context.palette.subText
                  : context.palette.text,
            ),
            onPressed:
                controller.selectionMode && controller.selectedIds.isNotEmpty
                ? () => _confirmDeleteSelected(controller)
                : controller.toggleSelectionMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horPagePadding),
        child: switch (controller.state) {
          ControllerState.init => LoadingWidget(),
          ControllerState.loading => LoadingWidget(),
          ControllerState.loaded => _LoadedWishlistPage(
            wishlists: controller.data!,
          ),
          ControllerState.error => ErrorPlaceholderWidget(
            error: controller.error,
            onRetry: controller.loadMyWishlist,
          ),
        },
      ),
    );
  }
}

class _LoadedWishlistPage extends StatelessWidget {
  final List<WishlistModel> wishlists;
  const _LoadedWishlistPage({required this.wishlists});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<WishlistListController>();
    final selectionMode = controller.selectionMode;
    return Column(
      children: [
        const SizedBox(height: smallSep),
        AddElemListButton(
          text: "Добавить новый вишлист",
          onTap: () => context.goNamed(wishlistCreateGoKey),
        ),
        const SizedBox(height: bigSep),
        Expanded(
          child: wishlists.isNotEmpty
              ? MelistReorderableListView(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 32),
                  onReorderItem: (oldIndex, newIndex) {
                    final order = controller.currentOrder;
                    if (order != null) {
                      order.reorder(oldIndex, newIndex);
                      controller.reorderWishlists(order);
                    }
                  },
                  itemCount: wishlists.length,
                  itemBuilder: (ctx, index) {
                    final e = wishlists[index];
                    return Column(
                      key: ValueKey(e.id),
                      children: [
                        ReorderableDelayedDragStartListener(
                          index: index,
                          enabled: !selectionMode,
                          child: WishListTile(
                            wishlistModel: e,
                            selected: selectionMode
                                ? controller.selectedIds.contains(e.id)
                                : null,
                            onSelect: (_) => controller.toggleSelect(e.id),
                            onTap: selectionMode
                                ? () => controller.toggleSelect(e.id)
                                : () {
                                    context.goNamed(
                                      wishlistGoKey,
                                      pathParameters: {'id': e.id.toString()},
                                    );
                                  },
                            onTapDelete: selectionMode
                                ? null
                                : () => context.guard(
                                    () => controller.deleteWishlists([e.id]),
                                  ),
                          ),
                        ),
                        if (index < wishlists.length - 1)
                          const SizedBox(height: bigSep),
                      ],
                    );
                  },
                )
              : EmptyPlaceholderWidget(),
        ),
      ],
    );
  }
}
