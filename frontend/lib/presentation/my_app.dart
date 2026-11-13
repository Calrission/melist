import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/di/setup.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:provider/provider.dart';

import 'controllers/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders(),
      child: const _MelistApp()
    );
  }
}

class _MelistApp extends StatelessWidget {
  const _MelistApp();

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp.router(
      title: 'MELIST',
      theme: Palette.fromUiTheme(themeController.theme).themeData,
      routerConfig: context.read<GoRouter>(),
    );
  }
}
