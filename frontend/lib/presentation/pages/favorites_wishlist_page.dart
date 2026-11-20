import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/domain/share_token.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
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
  GoRouter? _router;
  bool _isCurrentRoute = false;
  bool _refreshScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (identical(router, _router)) {
      return;
    }

    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    _router = router;
    router.routeInformationProvider.addListener(_onRouteChanged);
    _isCurrentRoute = _isFavoritesRoute(router);
    if (_isCurrentRoute) {
      _scheduleRefresh();
    }
  }

  void _scheduleRefresh() {
    if (_refreshScheduled) {
      return;
    }
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted && _isCurrentRoute) {
        context.read<FavoritesWishlistController>().loadMyFavoriteWishlists();
      }
    });
  }

  bool _isFavoritesRoute(GoRouter router) =>
      router.routeInformationProvider.value.uri.path == '/favorites';

  Future<void> _addFavorite() async {
    final tokenController = TextEditingController();
    final rawToken = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Добавить в избранное"),
        content: TextField(
          controller: tokenController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Токен или ссылка на вишлист",
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, tokenController.text),
            child: const Text("Добавить"),
          ),
        ],
      ),
    );
    tokenController.dispose();
    if (rawToken == null || !mounted) {
      return;
    }

    final token = parseShareToken(rawToken);
    if (token == null) {
      context.showMessage("Введите токен или ссылку на вишлист");
      return;
    }

    await context.guard(
      () => context.read<FavoritesWishlistController>().addWishlistToFavorites(
        AddFavoriteBody(shareToken: token),
      ),
      success: "Добавлено в избранное",
    );
  }

  void _onRouteChanged() {
    final router = _router;
    if (router == null) {
      return;
    }
    final isCurrentRoute = _isFavoritesRoute(router);
    if (isCurrentRoute && !_isCurrentRoute && mounted) {
      _scheduleRefresh();
    }
    _isCurrentRoute = isCurrentRoute;
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FavoritesWishlistController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: "Избранные вишлисты",
        actions: [
          IconButton(
            tooltip: "Добавить в избранное",
            onPressed: _addFavorite,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: switch (controller.state) {
        ControllerState.init => LoadingWidget(),
        ControllerState.loading => LoadingWidget(),
        ControllerState.error => ErrorPlaceholderWidget(
          error: controller.error,
          onRetry: controller.loadMyFavoriteWishlists,
        ),
        ControllerState.loaded => _LoadedState(wishlists: controller.data!),
      },
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
      padding: EdgeInsets.only(
        left: horPagePadding,
        right: horPagePadding,
        bottom: horPagePadding,
      ),
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
        return Padding(
          key: ValueKey(e),
          padding: EdgeInsetsGeometry.only(bottom: bigSep),
          child: WishListTile(
            wishlistModel: e,
            showOwner: true,
            onTapOwner: () => context.pushNamed(
              publicProfileGoKey,
              pathParameters: {'id': e.ownerId.toString()},
            ),
            showFavoriteAction: true,
            showEdit: false,
            onTap: () => context.pushNamed(
              favoriteWishlistGoKey,
              pathParameters: {'id': e.id.toString()},
            ),
            onToggleFavorite: (isFavorite) async {
              if (isFavorite) {
                return context.guard(
                  () => controller.deleteFavoriteWithoutUpdating(e.id),
                  success: "Удалено из избранного",
                );
              }
              final shareToken = e.shareToken;
              if (shareToken == null) {
                context.showMessage(
                  "Не удалось повторно добавить вишлист: отсутствует токен",
                );
                return false;
              }
              return context.guard(
                () => controller.addWishlistToFavorites(
                  AddFavoriteBody(shareToken: shareToken),
                ),
                success: "Добавлено в избранное",
              );
            },
          ),
        );
      },
    );
  }
}
