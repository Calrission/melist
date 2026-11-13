import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/wish_list_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishlistListPage extends StatefulWidget {
  const WishlistListPage({super.key});

  @override
  State<WishlistListPage> createState() => _WishlistListPageState();
}

class _WishlistListPageState extends State<WishlistListPage> {
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
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        title: Text("Виш-листы"),
        actions: [
          if (controller.selectionMode)
            TextButton(
              onPressed: controller.selectedIds.isEmpty
                  ? null
                  : () => context.guard(
                      controller.deleteSelected,
                      success: "Удалено",
                    ),
              child: Text("Удалить выбранные (${controller.selectedIds.length})"),
            ),
          TextButton(
            onPressed: controller.toggleSelectionMode,
            child: Text(controller.selectionMode ? "Отмена" : "Выбрать"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          context.goNamed(wishlistCreateGoKey);
        },
      ),
      body: Column(
        children: [
          switch (controller.state) {
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
        ],
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
    return Expanded(
      child: (wishlists.isNotEmpty)
        ? ReorderableListView.builder(
            buildDefaultDragHandles: false,
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
              return ReorderableDelayedDragStartListener(
                key: ValueKey(wishlists[index]),
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
              );
            },
          )
        : EmptyPlaceholderWidget(),
    );
  }
}
