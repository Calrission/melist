import 'package:flutter/foundation.dart';
import 'package:melist/presentation/controllers/app_bootstrap_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
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

    ChangeNotifierProvider<ProfileController>(
      create: (ctx) => ProfileController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<ThemeController>(create: (ctx) => ThemeController()),

    ChangeNotifierProvider<WishlistListController>(
      create: (ctx) => WishlistListController(repository: ctx.read()),
    ),

    ChangeNotifierProvider<WishlistController>(
      create: (ctx) => WishlistController(
        wishlistRepository: ctx.read(),
        wishRepository: ctx.read(),
        wishlistListController: ctx.read()
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
      ),
    ),
  ];
}
