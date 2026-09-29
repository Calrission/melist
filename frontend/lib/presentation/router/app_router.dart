import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/pages/error_page.dart';
import 'package:melist/presentation/pages/home_page.dart';
import 'package:melist/presentation/pages/wishlist_form_page.dart';
import 'package:melist/presentation/pages/wishlist_list_page.dart';
import 'package:melist/presentation/router/session_gate.dart';
import 'package:provider/provider.dart';
import 'package:talker/talker.dart';

const String homeGoKey = 'home';
const String wishlistsGoKey= 'wishlists';
const String wishlistCreateGoKey = 'wishlist_create';
const String wishlistEditGoKey = 'wishlist_edit';

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
          builder: (_, _) => const HomePage()
        ),
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
          ]
        )
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
