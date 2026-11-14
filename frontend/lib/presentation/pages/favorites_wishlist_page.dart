import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/domain/share_token.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/melist_reorderable_list_view.dart';
import 'package:melist/presentation/widgets/wishlist_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';

class FavoritesWishlistPage extends StatefulWidget {
  const FavoritesWishlistPage({super.key});

  @override
  State<FavoritesWishlistPage> createState() => _FavoritesWishlistPageState();
}

class _FavoritesWishlistPageState extends State<FavoritesWishlistPage> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final token = parseShareToken(_tokenController.text);
    if (token == null) {
      context.showMessage("Введите токен или ссылку");
      return;
    }
    final added = await context.guard(
      () => context.read<FavoritesWishlistController>().addWishlistToFavorites(
        AddFavoriteBody(shareToken: token),
      ),
      success: "Добавлено в избранное",
    );
    if (added) {
      _tokenController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FavoritesWishlistController>();
    return Scaffold(
      appBar: MelistAppBar(title: "Избранное"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      hintText: 'Токен или ссылка на чужой вишлист',
                    ),
                  ),
                ),
                OutlinedButton(onPressed: _add, child: Text("Добавить")),
              ],
            ),
          ),
          Expanded(
            child: switch (controller.state) {
              ControllerState.init => LoadingWidget(),
              ControllerState.loading => LoadingWidget(),
              ControllerState.error => ErrorPlaceholderWidget(
                error: controller.error,
                onRetry: controller.loadMyFavoriteWishlists,
              ),
              ControllerState.loaded => _LoadedState(
                wishlists: controller.data!,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _LoadedState extends StatelessWidget {
  final List<WishlistModel> _wishlists;
  const _LoadedState({required this._wishlists});

  @override
  Widget build(BuildContext context) {
    if (_wishlists.isEmpty) {
      return EmptyPlaceholderWidget();
    }
    final controller = context.read<FavoritesWishlistController>();
    return MelistReorderableListView(
      onReorderItem: (oldIndex, newIndex) {
        final order = controller.currentOrder;
        if (order != null) {
          order.reorder(oldIndex, newIndex);
          controller.reorderFavorites(order);
        }
      },
      itemCount: _wishlists.length,
      itemBuilder: (context, index) {
        final e = _wishlists[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(e),
          index: index,
          child: WishListTile(
            wishlistModel: e,
            showEdit: false,
            onTap: e.shareToken == null
                ? null
                : () => context.pushNamed(
                    sharedWishlistGoKey,
                    pathParameters: {'token': e.shareToken!},
                  ),
            onTapDelete: () => context.guard(
              () => controller.deleteFavoriteById(e.id),
              success: "Удалено из избранного",
            ),
          ),
        );
      },
    );
  }
}
