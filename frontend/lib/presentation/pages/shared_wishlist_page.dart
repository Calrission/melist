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
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
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
  final int? favoriteWishlistId;

  const SharedWishlistPage({super.key, required this.token})
    : favoriteWishlistId = null;

  const SharedWishlistPage.fromFavorite({super.key, required int wishlistId})
    : token = '',
      favoriteWishlistId = wishlistId;

  @override
  State<SharedWishlistPage> createState() => _SharedWishlistPageState();
}

class _SharedWishlistPageState extends State<SharedWishlistPage> {
  String? _token;
  Object? _favoriteLoadError;

  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      final favoriteWishlistId = widget.favoriteWishlistId;
      if (favoriteWishlistId != null) {
        _loadFavoriteWishlist(favoriteWishlistId);
      } else {
        _loadByToken(widget.token);
      }
      context.read<WishlistSubscriptionsController>().ensureLoaded();
      final profile = context.read<ProfileController>();
      if (profile.profile == null) {
        profile.loadProfile();
      }
    });
  }

  Future<void> _loadFavoriteWishlist(int wishlistId) async {
    final favorites = context.read<FavoritesWishlistController>();
    await favorites.loadMyFavoriteWishlists();
    if (!mounted) {
      return;
    }

    if (favorites.state == ControllerState.error) {
      setState(() => _favoriteLoadError = favorites.error);
      return;
    }

    WishlistModel? wishlist;
    for (final item in favorites.data ?? const <WishlistModel>[]) {
      if (item.id == wishlistId) {
        wishlist = item;
        break;
      }
    }
    final token = wishlist?.shareToken;
    if (token == null) {
      setState(
        () => _favoriteLoadError = StateError(
          "Не удалось открыть избранный вишлист",
        ),
      );
      return;
    }
    _loadByToken(token);
  }

  void _loadByToken(String token) {
    _token = token;
    context.read<SharedWishlistController>().loadByToken(token);
  }

  void _retry() {
    final favoriteWishlistId = widget.favoriteWishlistId;
    if (favoriteWishlistId != null) {
      setState(() => _favoriteLoadError = null);
      _loadFavoriteWishlist(favoriteWishlistId);
    } else {
      _loadByToken(widget.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SharedWishlistController>();
    final myId = context.watch<ProfileController>().profile?.id;
    final favorites = context.watch<FavoritesWishlistController>();
    final subscriptions = context.watch<WishlistSubscriptionsController>();
    final token = _token;
    final ready =
        token != null &&
        controller.state == ControllerState.loaded &&
        controller.token == token;
    final wishlist = ready ? controller.data! : null;
    final isOwn = wishlist != null && wishlist.ownerId == myId;
    final error =
        _favoriteLoadError ??
        (token != null && controller.token == token ? controller.error : null);
    return Scaffold(
      appBar: MelistAppBar(
        title: wishlist?.name ?? "Вишлист по ссылке",
        actions: [
          if (wishlist != null && !isOwn)
            IconButton(
              tooltip: favorites.contains(wishlist.id)
                  ? "Убрать из избранного"
                  : "В избранное",
              onPressed: () => context.guard(
                () => favorites.contains(wishlist.id)
                    ? favorites.deleteFavoriteById(wishlist.id)
                    : favorites.addWishlistToFavorites(
                        AddFavoriteBody(shareToken: token!),
                      ),
                success: favorites.contains(wishlist.id)
                    ? "Удалено из избранного"
                    : "Добавлено в избранное",
              ),
              icon: Icon(
                favorites.contains(wishlist.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: context.palette.accent,
              ),
            ),
          if (wishlist != null &&
              !isOwn &&
              wishlist.visibility == WishlistVisibility.public)
            IconButton(
              tooltip: subscriptions.isSubscribed(wishlist.id)
                  ? "Отключить уведомления"
                  : "Включить уведомления",
              onPressed: () => context.guard(
                () => subscriptions.isSubscribed(wishlist.id)
                    ? subscriptions.unsubscribe(wishlist.id)
                    : subscriptions.subscribe(wishlist.id),
                success: subscriptions.isSubscribed(wishlist.id)
                    ? "Уведомления отключены"
                    : "Уведомления включены",
              ),
              icon: Icon(
                subscriptions.isSubscribed(wishlist.id)
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined
              ),
            ),
        ],
      ),
      body: error != null
          ? ErrorPlaceholderWidget(error: error, onRetry: _retry)
          : ready
          ? _LoadedShared(wishlist: controller.data!)
          : LoadingWidget(),
    );
  }
}

class _LoadedShared extends StatelessWidget {
  final WishlistModel wishlist;
  const _LoadedShared({required this.wishlist});

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
      () => context.read<SharedWishlistController>().copyWishTo(
        wish.id,
        targetId,
      ),
      success: "Скопировано",
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<ProfileController>().profile?.id;
    final isOwn = myId != null && myId == wishlist.ownerId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wishlist.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                wishlist.description!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.pushNamed(
                  publicProfileGoKey,
                  pathParameters: {'id': wishlist.ownerId.toString()},
                ),
                child: const Text("Профиль владельца"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: wishlist.items.isEmpty
                ? EmptyPlaceholderWidget()
                : ListView(
                    children: [
                      for (final wish in wishlist.items)
                        WishTile(
                          wishModel: wish,
                          onTap: () => context.pushNamed(
                            wishDetailsGoKey,
                            pathParameters: {'id': wish.id.toString()},
                            extra: WishDetailsArguments(wish: wish),
                          ),
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
      ),
    );
  }
}
