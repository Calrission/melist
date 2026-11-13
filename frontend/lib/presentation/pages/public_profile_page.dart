import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/public_profile_controller.dart';
import 'package:melist/presentation/controllers/user_subscriptions_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/wish_list_tile.dart';
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
      context.read<UserSubscriptionsController>().ensureLoaded();
      context.read<WishlistSubscriptionsController>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PublicProfileController>();
    final ready =
        controller.state == ControllerState.loaded &&
        controller.data?.user.id == widget.userId;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text("Профиль пользователя"),
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
    final users = context.watch<UserSubscriptionsController>();
    final wishlistSubs = context.watch<WishlistSubscriptionsController>();
    final isMe = myId == user.id;
    final subscribed = users.isSubscribed(user.id);

    return Column(
      children: [
        if (user.avatarUrl != null)
          ClipOval(
            child: Image.network(
              user.avatarUrl!,
              width: 96,
              errorBuilder: (_, _, _) => const Icon(Icons.person),
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            ),
          ),
        Text(
          'id = ${user.id}\n'
          'firstName = ${user.firstName}\n'
          'lastName = ${user.lastName}\n'
          'username = ${user.username}\n'
          'birthday = ${user.birthday?.toIso8601String().substring(0, 10)}',
        ),
        if (!isMe)
          FilledButton(
            onPressed: () => context.guard(
              () => subscribed
                  ? users.unsubscribe(user.id)
                  : users.subscribe(user.id),
            ),
            child: Text(subscribed ? "Отписаться от профиля" : "Подписаться на профиль"),
          ),
        Text("Публичные вишлисты:"),
        Expanded(
          child: profile.wishlists.isEmpty
              ? EmptyPlaceholderWidget()
              : ListView(
                  children: [
                    for (final wishlist in profile.wishlists)
                      WishListTile(
                        wishlistModel: wishlist,
                        showEdit: false,
                        onTap: wishlist.shareToken == null
                            ? () => context.showMessage(
                                "У вишлиста нет ссылки — владелец ещё не делился им",
                              )
                            : () => context.pushNamed(
                                sharedWishlistGoKey,
                                pathParameters: {'token': wishlist.shareToken!},
                              ),
                        actions: [
                          if (!isMe)
                            TextButton(
                              onPressed: () => context.guard(
                                () => wishlistSubs.isSubscribed(wishlist.id)
                                    ? wishlistSubs.unsubscribe(wishlist.id)
                                    : wishlistSubs.subscribe(wishlist.id),
                              ),
                              child: Text(
                                wishlistSubs.isSubscribed(wishlist.id)
                                    ? "Отписаться"
                                    : "Подписаться",
                              ),
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
