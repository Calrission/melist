import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/pages/error_page.dart';
import 'package:melist/presentation/pages/home_page.dart';
import 'package:melist/presentation/pages/wishlist_list_page.dart';
import 'package:melist/presentation/widgets/session_gate.dart';
import 'package:provider/provider.dart';
import 'package:talker/talker.dart';

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: kDebugMode,
  routes: [
    ShellRoute(
      builder: (_, _, child) => SessionGate(child: child),
      routes: [HomePage.route, WishlistListPage.route],
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
