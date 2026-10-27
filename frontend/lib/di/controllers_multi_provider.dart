import 'package:flutter/foundation.dart';
import 'package:melist/presentation/controllers/app_bootstrap_controller.dart';
import 'package:melist/presentation/controllers/deep_link_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/public_profile_controller.dart';
import 'package:melist/presentation/controllers/shared_wishlist_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/controllers/user_subscriptions_controller.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/controllers/wishlist_subscriptions_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ControllersMultiProvider {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AppBootstrapController>(
      create: (ctx) => AppBootstrapController(
        session: ctx.read(),
        telegram: ctx.read(),
        allowDebug: kDebugMode,
      )..restore(),
    ),

    Provider<DeepLinkController>(
      create: (ctx) => DeepLinkController(telegram: ctx.read()),
    ),

    ChangeNotifierProvider<ThemeController>(create: (ctx) => ThemeController()),

    ChangeNotifierProvider<ProfileController>(
      create: (ctx) => ProfileController(
        repository: ctx.read(),
        theme: ctx.read(),
      ),
    ),

    ChangeNotifierProvider<PublicProfileController>(
      create: (ctx) => PublicProfileController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<WishlistListController>(
      create: (ctx) => WishlistListController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<FavoritesWishlistController>(
      create: (ctx) => FavoritesWishlistController(repository: ctx.read())..loadMyFavoriteWishlists(),
    ),

    ChangeNotifierProvider<WishlistSubscriptionsController>(
      create: (ctx) => WishlistSubscriptionsController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<UserSubscriptionsController>(
      create: (ctx) => UserSubscriptionsController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<WishlistController>(
      create: (ctx) => WishlistController(
        wishlistRepository: ctx.read(),
        wishRepository: ctx.read(),
        wishlistListController: ctx.read()
      ),
    ),

    ChangeNotifierProvider<WishesController>(
      create: (ctx) => WishesController(
        repository: ctx.read(),
        wishlists: ctx.read(),
        wishlist: ctx.read(),
      ),
    ),

    ChangeNotifierProvider<SharedWishlistController>(
      create: (ctx) => SharedWishlistController(
        wishlistRepository: ctx.read(),
        wishRepository: ctx.read(),
        wishlists: ctx.read(),
        wishes: ctx.read(),
      ),
    ),

    ChangeNotifierProvider<WishlistFormController>(
      create: (ctx) => WishlistFormController(
        repository: ctx.read(),
        wishlists: ctx.read(),
        wishlist: ctx.read(),
      ),
    ),

    ChangeNotifierProvider<WishFormController>(
      create: (ctx) => WishFormController(
        repository: ctx.read(),
        wishlists: ctx.read(),
        wishlist: ctx.read(),
        wishes: ctx.read(),
      ),
    ),
  ];
}
