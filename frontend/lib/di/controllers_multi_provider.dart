import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/app_bootstrap_controller.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
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

    ChangeNotifierProvider<ThemeController>(
      create: (ctx) => ThemeController()
    ),

    ChangeNotifierProvider<WishlistFormController>(
      create: (ctx) => WishlistFormController(
        repository: ctx.read<IWishlistRepository>(),
      ),
    ),

    ChangeNotifierProxyProvider<WishlistFormController, WishlistListController>(
      create: (ctx) => WishlistListController(
        repository: ctx.read<IWishlistRepository>(),
      ),
      update: (ctx, form, list) {
        final controller = list ?? ctx.read<WishlistListController>();
        if (form.state == ControllerState.loaded && form.data != null) {
          scheduleMicrotask(() async {
            await controller.refreshMyWishlist();
            form.reset();
          });
        }
        return controller;
      },
    ),
  ];
}
