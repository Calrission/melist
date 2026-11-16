import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/user_subscriptions_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/wishlist_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

/// Wishlist and profile subscriptions (31, 32, 34, 35).
class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      context.read<WishlistSubscriptionsController>().load();
      context.read<UserSubscriptionsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlists = context.watch<WishlistSubscriptionsController>();
    final users = context.watch<UserSubscriptionsController>();
    return Scaffold(
      appBar: MelistAppBar(title: "Подписки"),
      body: ListView(
        padding: const EdgeInsets.all(horPagePadding),
        children: [
          Text(
            "Все обновления от вишлистов и профилей, на которые вы подписаны.",
            style: TextStyle(color: context.palette.subText, fontSize: 13),
          ),
          const SizedBox(height: singleSep),
          _SubscriptionsSection(
            title: "Вишлисты",
            icon: Icons.card_giftcard_outlined,
            count: wishlists.state == ControllerState.loaded
                ? wishlists.data!.length
                : null,
            children: switch (wishlists.state) {
              ControllerState.init ||
              ControllerState.loading => [const LoadingWidget()],
              ControllerState.error => [
                ErrorPlaceholderWidget(
                  error: wishlists.error,
                  onRetry: wishlists.load,
                ),
              ],
              ControllerState.loaded =>
                wishlists.data!.isEmpty
                    ? const [
                        _EmptySubscriptions(
                          message: "Вы пока не подписаны на вишлисты",
                          icon: Icons.card_giftcard_outlined,
                        ),
                      ]
                    : [
                        for (final wishlist in wishlists.data!)
                          WishListTile(
                            wishlistModel: wishlist,
                            showEdit: false,
                            onTap: wishlist.shareToken == null
                                ? () => context.pushNamed(
                                    publicProfileGoKey,
                                    pathParameters: {
                                      'id': wishlist.ownerId.toString(),
                                    },
                                  )
                                : () => context.pushNamed(
                                    sharedWishlistGoKey,
                                    pathParameters: {
                                      'token': wishlist.shareToken!,
                                    },
                                  ),
                            actions: [
                              IconButton(
                                tooltip: "Отписаться от вишлиста",
                                onPressed: () => context.guard(
                                  () => wishlists.unsubscribe(wishlist.id),
                                ),
                                icon: const Icon(
                                  Icons.notifications_off_outlined,
                                ),
                              ),
                            ],
                          ),
                      ],
            },
          ),
          const SizedBox(height: bigSep),
          _SubscriptionsSection(
            title: "Профили",
            icon: Icons.people_outline,
            count: users.state == ControllerState.loaded
                ? users.data!.length
                : null,
            children: switch (users.state) {
              ControllerState.init ||
              ControllerState.loading => [const LoadingWidget()],
              ControllerState.error => [
                ErrorPlaceholderWidget(error: users.error, onRetry: users.load),
              ],
              ControllerState.loaded =>
                users.data!.isEmpty
                    ? const [
                        _EmptySubscriptions(
                          message: "Вы пока не подписаны на профили",
                          icon: Icons.people_outline,
                        ),
                      ]
                    : [
                        for (final user in users.data!)
                          _UserSubscriptionTile(
                            user: user,
                            onTap: () => context.pushNamed(
                              publicProfileGoKey,
                              pathParameters: {'id': user.id.toString()},
                            ),
                            onUnsubscribe: () =>
                                context.guard(() => users.unsubscribe(user.id)),
                          ),
                      ],
            },
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({
    required this.title,
    required this.icon,
    required this.count,
    required this.children,
  });

  final String title;
  final IconData icon;
  final int? count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: context.palette.accent),
            const SizedBox(width: smallSep),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.palette.containerAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    color: context.palette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: smallSep),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const SizedBox(height: smallSep),
        ],
      ],
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  const _EmptySubscriptions({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: context.palette.container,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: context.palette.subText),
          const SizedBox(height: smallSep),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.subText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _UserSubscriptionTile extends StatelessWidget {
  const _UserSubscriptionTile({
    required this.user,
    required this.onTap,
    required this.onUnsubscribe,
  });

  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onUnsubscribe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.container,
      borderRadius: BorderRadius.circular(borderRadius),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: CircleAvatar(
          backgroundColor: context.palette.containerAccent,
          child: Icon(Icons.person_outline, color: context.palette.accent),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          "@${user.username}",
          style: TextStyle(color: context.palette.subText, fontSize: 12),
        ),
        onTap: onTap,
        trailing: IconButton(
          tooltip: "Отписаться от профиля",
          onPressed: onUnsubscribe,
          icon: const Icon(Icons.notifications_off_outlined),
        ),
      ),
    );
  }
}
