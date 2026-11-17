import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/public_profile_controller.dart';
import 'package:melist/presentation/controllers/user_subscriptions_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:melist/presentation/widgets/wishlist_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

/// Another user's profile with public wishlists (25, 30, 33, 35).
class PublicProfilePage extends StatefulWidget {
  final int userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      context.read<PublicProfileController>().loadById(widget.userId);
      context.read<FavoritesWishlistController>().loadMyFavoriteWishlists();
      context.read<UserSubscriptionsController>().ensureLoaded();
      context.read<WishlistSubscriptionsController>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PublicProfileController>();
    final users = context.watch<UserSubscriptionsController>();
    final myId = context.watch<ProfileController>().profile?.id;
    final ready =
        controller.state == ControllerState.loaded &&
        controller.data?.user.id == widget.userId;
    final isMe = myId == widget.userId;
    final subscribed = users.isSubscribed(widget.userId);
    return Scaffold(
      appBar: MelistAppBar(
        title: "Профиль пользователя",
        actions: ready && !isMe
            ? [
                IconButton(
                  tooltip: subscribed
                      ? "Отключить обновления профиля"
                      : "Подписаться на обновления профиля",
                  onPressed: () => context.guard(
                    () => subscribed
                        ? users.unsubscribe(widget.userId)
                        : users.subscribe(widget.userId),
                    success: subscribed
                        ? "Обновления профиля отключены"
                        : "Вы подписались на обновления профиля",
                  ),
                  icon: Icon(
                    subscribed
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_outlined,
                  ),
                ),
              ]
            : [],
      ),
      body: controller.state == ControllerState.error
          ? ErrorPlaceholderWidget(
              error: controller.error,
              onRetry: () => controller.loadById(widget.userId),
            )
          : ready
          ? _LoadedProfile(profile: controller.data!)
          : LoadingWidget(),
    );
  }
}

class _LoadedProfile extends StatelessWidget {
  final PublicProfileModel profile;
  const _LoadedProfile({required this.profile});

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final myId = context.watch<ProfileController>().profile?.id;
    final favorites = context.watch<FavoritesWishlistController>();
    final subscriptions = context.watch<WishlistSubscriptionsController>();
    final isMe = myId == user.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(horPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileWidget(userModel: user, allowBirthdayEdit: isMe),
          SizedBox(height: singleSep),
          if (profile.wishlists.isEmpty)
            EmptyPlaceholderWidget()
          else
            for (final (index, wishlist) in profile.wishlists.indexed) ...[
              if (index > 0) const SizedBox(height: singleSep),
              WishListTile(
                wishlistModel: wishlist,
                showFavoriteAction: true,
                showEdit: false,
                isFavorite: favorites.contains(wishlist.id),
                actions: [
                  if (!isMe)
                    IconButton(
                      tooltip: subscriptions.isSubscribed(wishlist.id)
                          ? "Отключить уведомления о вишлисте"
                          : "Подписаться на обновления вишлиста",
                      onPressed: () {
                        final subscribed = subscriptions.isSubscribed(
                          wishlist.id,
                        );
                        context.guard(
                          () => subscribed
                              ? subscriptions.unsubscribe(wishlist.id)
                              : subscriptions.subscribe(wishlist.id),
                          success: subscribed
                              ? "Уведомления о вишлисте отключены"
                              : "Вы подписались на обновления вишлиста",
                        );
                      },
                      icon: Icon(
                        subscriptions.isSubscribed(wishlist.id)
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none_outlined,
                      ),
                    ),
                ],
                onTap: wishlist.shareToken == null
                    ? () => context.showMessage(
                        "У вишлиста нет ссылки — владелец ещё не делился им",
                      )
                    : () => context.pushNamed(
                        publicProfileWishlistGoKey,
                        pathParameters: {
                          'id': user.id.toString(),
                          'token': wishlist.shareToken!,
                        },
                      ),
                onToggleFavorite: (isFavorite) async {
                  if (isFavorite) {
                    return context.guard(
                      () => favorites.deleteFavoriteById(wishlist.id),
                      success: "Удалено из избранного",
                    );
                  }
                  final shareToken = wishlist.shareToken;
                  if (shareToken == null) {
                    context.showMessage(
                      "Не удалось добавить в избранное: отсутствует токен",
                    );
                    return false;
                  }
                  return context.guard(
                    () => favorites.addWishlistToFavorites(
                      AddFavoriteBody(shareToken: shareToken),
                    ),
                    success: "Добавлено в избранное",
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}
