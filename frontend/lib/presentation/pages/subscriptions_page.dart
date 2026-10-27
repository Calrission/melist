import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/user_subscriptions_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/wish_list_tile.dart';
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
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text("Подписки"),
      ),
      body: ListView(
        children: [
          Text("Вишлисты:"),
          ...switch (wishlists.state) {
            ControllerState.init || ControllerState.loading => [LoadingWidget()],
            ControllerState.error => [
              ErrorPlaceholderWidget(
                error: wishlists.error,
                onRetry: wishlists.load,
              ),
            ],
            ControllerState.loaded => [
              if (wishlists.data!.isEmpty) Text("Нет подписок на вишлисты"),
              for (final wishlist in wishlists.data!)
                WishListTile(
                  wishlistModel: wishlist,
                  showEdit: false,
                  onTap: wishlist.shareToken == null
                      ? () => context.pushNamed(
                          publicProfileGoKey,
                          pathParameters: {'id': wishlist.ownerId.toString()},
                        )
                      : () => context.pushNamed(
                          sharedWishlistGoKey,
                          pathParameters: {'token': wishlist.shareToken!},
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => context.guard(
                        () => wishlists.unsubscribe(wishlist.id),
                      ),
                      child: Text("Отписаться"),
                    ),
                  ],
                ),
            ],
          },
          Divider(),
          Text("Профили:"),
          ...switch (users.state) {
            ControllerState.init || ControllerState.loading => [LoadingWidget()],
            ControllerState.error => [
              ErrorPlaceholderWidget(error: users.error, onRetry: users.load),
            ],
            ControllerState.loaded => [
              if (users.data!.isEmpty) Text("Нет подписок на профили"),
              for (final user in users.data!)
                ListTile(
                  title: Text(
                    [user.firstName, user.lastName].whereType<String>().join(' '),
                  ),
                  subtitle: Text("id: ${user.id} | @${user.username}"),
                  onTap: () => context.pushNamed(
                    publicProfileGoKey,
                    pathParameters: {'id': user.id.toString()},
                  ),
                  trailing: TextButton(
                    onPressed: () => context.guard(
                      () => users.unsubscribe(user.id),
                    ),
                    child: Text("Отписаться"),
                  ),
                ),
            ],
          },
        ],
      ),
    );
  }
}
