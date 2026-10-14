import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/pages/error_page.dart';
import 'package:melist/presentation/pages/favorites_wishlist_page.dart';
import 'package:melist/presentation/pages/home_page.dart';
import 'package:melist/presentation/pages/wish_form_page.dart';
import 'package:melist/presentation/pages/wishlist_form_page.dart';
import 'package:melist/presentation/pages/wishlist_list_page.dart';
import 'package:melist/presentation/pages/wishlist_page.dart';
import 'package:melist/presentation/router/session_gate.dart';
import 'package:provider/provider.dart';
import 'package:talker/talker.dart';

const String homeGoKey = 'home';
const String wishlistsGoKey= 'wishlists';
const String wishlistGoKey = 'wishlist';
const String wishlistCreateGoKey = 'wishlist_create';
const String wishlistEditGoKey = 'wishlist_edit';
const String wishCreateGoKey = 'wish_create';
const String wishlistFavoritesGoKey = 'wishlist_favorites';

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: kDebugMode,
  routes: [
    ShellRoute(
      builder: (_, _, child) => SessionGate(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: homeGoKey,
          builder: (_, _) => const HomePage(),
          routes: [
            GoRoute(
              path: '/wishlists',
              name: wishlistsGoKey,
              builder: (_, _) => const WishlistListPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: wishlistCreateGoKey,
                  builder: (_, _) => const WishlistFormPage()
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: wishlistEditGoKey,
                  builder: (context, state) => WishlistFormPage(
                    wishlistId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: wishlistGoKey,
                  builder: (context, state) => WishlistPage(
                    wishlistId: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'wish/new',
                      name: wishCreateGoKey,
                      builder: (context, state) => WishFormPage(
                        fromWishlistId: int.parse(state.pathParameters['id']!)
                      )
                    )
                  ]
                ),
              ]
            ),
            GoRoute(
              path: "/favorites",
              name: wishlistFavoritesGoKey,
              builder: (_, _) => FavoritesWishlistPage(),
            )
          ]
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) {
    context.read<Talker>().error(
      'Error GoRoute ${state.fullPath}',
      state.error,
    );
    return ErrorPage();
  },
);
