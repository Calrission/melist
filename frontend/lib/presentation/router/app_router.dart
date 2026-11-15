import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/pages/error_page.dart';
import 'package:melist/presentation/pages/favorites_wishlist_page.dart';
import 'package:melist/presentation/pages/home_page.dart';
import 'package:melist/presentation/pages/public_profile_page.dart';
import 'package:melist/presentation/pages/shared_wishlist_page.dart';
import 'package:melist/presentation/pages/settings_page.dart';
import 'package:melist/presentation/pages/subscriptions_page.dart';
import 'package:melist/presentation/pages/wish_form_page.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/pages/wish_picker_page.dart';
import 'package:melist/presentation/pages/wishes_page.dart';
import 'package:melist/presentation/pages/wishlist_form_page.dart';
import 'package:melist/presentation/pages/wishlist_list_page.dart';
import 'package:melist/presentation/pages/wishlist_page.dart';
import 'package:melist/presentation/router/session_gate.dart';
import 'package:provider/provider.dart';
import 'package:talker/talker.dart';

const String homeGoKey = 'home';
const String wishlistsGoKey = 'wishlists';
const String wishlistGoKey = 'wishlist';
const String wishlistCreateGoKey = 'wishlist_create';
const String wishlistEditGoKey = 'wishlist_edit';
const String wishCreateGoKey = 'wish_create';
const String wishAttachGoKey = 'wish_attach';
const String wishlistFavoritesGoKey = 'wishlist_favorites';
const String wishesGoKey = 'wishes';
const String wishNewGoKey = 'wish_new';
const String wishEditGoKey = 'wish_edit';
const String wishDetailsGoKey = 'wish_details';
const String sharedWishlistGoKey = 'shared_wishlist';
const String publicProfileGoKey = 'public_profile';
const String favoriteWishlistGoKey = 'favorite_wishlist';
const String publicProfileWishlistGoKey = 'public_profile_wishlist';
const String subscriptionsGoKey = 'subscriptions';
const String settingsGoKey = 'settings';

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
                  builder: (_, _) => const WishlistFormPage(),
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
                        fromWishlistId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    GoRoute(
                      path: 'wish/attach',
                      name: wishAttachGoKey,
                      builder: (context, state) => WishPickerPage(
                        wishlistId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/wishes',
              name: wishesGoKey,
              builder: (_, _) => const WishesPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: wishNewGoKey,
                  builder: (_, _) => const WishFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  name: wishDetailsGoKey,
                  builder: (context, state) {
                    final extra = state.extra;
                    return WishDetailsPage(
                      wishId: int.parse(state.pathParameters['id']!),
                      initialWish: extra is WishDetailsArguments
                          ? extra.wish
                          : null,
                      sourceWishlistName: extra is WishDetailsArguments
                          ? extra.sourceWishlistName
                          : null,
                    );
                  },
                ),
                GoRoute(
                  path: ':id/edit',
                  name: wishEditGoKey,
                  builder: (context, state) => WishFormPage(
                    wishId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: "/favorites",
              name: wishlistFavoritesGoKey,
              builder: (_, _) => FavoritesWishlistPage(),
            ),
            GoRoute(
              path: '/favorites/:id',
              name: favoriteWishlistGoKey,
              builder: (context, state) => SharedWishlistPage.fromFavorite(
                wishlistId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/shared/:token',
              name: sharedWishlistGoKey,
              builder: (context, state) =>
                  SharedWishlistPage(token: state.pathParameters['token']!),
            ),
            GoRoute(
              path: '/users/:id',
              name: publicProfileGoKey,
              builder: (context, state) => PublicProfilePage(
                userId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/users/:id/wishlists/:token',
              name: publicProfileWishlistGoKey,
              builder: (context, state) =>
                  SharedWishlistPage(token: state.pathParameters['token']!),
            ),
            GoRoute(
              path: '/settings',
              name: settingsGoKey,
              builder: (_, _) => const SettingsPage(),
            ),
            GoRoute(
              path: '/subscriptions',
              name: subscriptionsGoKey,
              builder: (_, _) => const SubscriptionsPage(),
            ),
          ],
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
