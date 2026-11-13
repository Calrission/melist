import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/shared_wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

/// Read-only view of a wishlist opened by share token (7, 8.1, 4.3, 30).
class SharedWishlistPage extends StatefulWidget {
  final String token;
  const SharedWishlistPage({super.key, required this.token});

  @override
  State<SharedWishlistPage> createState() => _SharedWishlistPageState();
}

class _SharedWishlistPageState extends State<SharedWishlistPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      context.read<SharedWishlistController>().loadByToken(widget.token);
      context.read<WishlistSubscriptionsController>().ensureLoaded();
      final profile = context.read<ProfileController>();
      if (profile.profile == null) {
        profile.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SharedWishlistController>();
    final ready =
        controller.state == ControllerState.loaded &&
        controller.token == widget.token;
    return Scaffold(
      appBar: MelistAppBar(title: "Вишлист по ссылке"),
      body: controller.state == ControllerState.error
          ? ErrorPlaceholderWidget(
              error: controller.error,
              onRetry: () => controller.loadByToken(widget.token),
            )
          : ready
              ? _LoadedShared(wishlist: controller.data!, token: widget.token)
              : LoadingWidget(),
    );
  }
}

class _LoadedShared extends StatelessWidget {
  final WishlistModel wishlist;
  final String token;
  const _LoadedShared({required this.wishlist, required this.token});

  Future<void> _copy(BuildContext context, WishModel wish) async {
    final lists = context.read<WishlistListController>();
    if (lists.data == null) {
      await lists.refreshMyWishlist();
    }
    if (!context.mounted) {
      return;
    }
    final mine = lists.data ?? const <WishlistModel>[];
    if (mine.isEmpty) {
      context.showMessage("Сначала создайте свой вишлист");
      return;
    }
    final targetId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text("Скопировать «${wish.name}» в:"),
        children: [
          for (final list in mine)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, list.id),
              child: Text(list.name),
            ),
        ],
      ),
    );
    if (targetId == null || !context.mounted) {
      return;
    }
    context.guard(
      () => context.read<SharedWishlistController>().copyWishTo(wish.id, targetId),
      success: "Скопировано",
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<ProfileController>().profile?.id;
    final favorites = context.watch<FavoritesWishlistController>();
    final subscriptions = context.watch<WishlistSubscriptionsController>();
    final isOwn = myId != null && myId == wishlist.ownerId;
    final inFavorites = favorites.contains(wishlist.id);
    final subscribed = subscriptions.isSubscribed(wishlist.id);

    return Column(
      children: [
        Text(wishlist.name),
        if (wishlist.description != null) Text(wishlist.description!),
        Text(
          "owner: ${wishlist.ownerId} | visibility: ${wishlist.visibility.name}"
          " | color: ${wishlist.color}${isOwn ? ' | это ваш вишлист' : ''}",
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => context.pushNamed(
                publicProfileGoKey,
                pathParameters: {'id': wishlist.ownerId.toString()},
              ),
              child: Text("Профиль владельца"),
            ),
            if (!isOwn)
              OutlinedButton(
                onPressed: () => context.guard(
                  () => inFavorites
                      ? favorites.deleteFavoriteById(wishlist.id)
                      : favorites.addWishlistToFavorites(
                          AddFavoriteBody(shareToken: token),
                        ),
                  success: inFavorites
                      ? "Удалено из избранного"
                      : "Добавлено в избранное",
                ),
                child: Text(inFavorites ? "Убрать из избранного" : "В избранное"),
              ),
            if (!isOwn && wishlist.visibility == WishlistVisibility.public)
              OutlinedButton(
                onPressed: () => context.guard(
                  () => subscribed
                      ? subscriptions.unsubscribe(wishlist.id)
                      : subscriptions.subscribe(wishlist.id),
                ),
                child: Text(subscribed ? "Отписаться" : "Подписаться"),
              ),
          ],
        ),
        Expanded(
          child: wishlist.items.isEmpty
              ? EmptyPlaceholderWidget()
              : ListView(
                  children: [
                    for (final wish in wishlist.items)
                      WishTile(
                        wishModel: wish,
                        actions: [
                          if (!isOwn)
                            IconButton(
                              tooltip: "Скопировать к себе",
                              onPressed: () => _copy(context, wish),
                              icon: Icon(Icons.copy),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
