import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/di/setup.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

import 'controllers/theme_controller.dart';
import 'pages/home_page.dart';
import 'widgets/not_telegram_error_widget.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders(),
      child: const _RestoredApp(),
    );
  }
}

class _RestoredApp extends StatefulWidget {
  const _RestoredApp();

  @override
  State<_RestoredApp> createState() => _RestoredAppState();
}

class _RestoredAppState extends State<_RestoredApp> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final telegram = context.read<ITelegramRepository>();
    await context.read<AuthSession>().restoreSession(
      initData: telegram.initData,
      allowDebug: kDebugMode,
    );
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telegram = context.read<ITelegramRepository>();
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: 'MELIST',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        extensions: [
          PaletteThemeExtension(palette: Palette.fromUiTheme(themeController.theme)),
        ]
      ),
      home: (!_ready)
        ? LoadingWidget()
        : telegram.isAvailable
          ? const MyHomePage()
          : const NotTelegramErrorWidget(),
    );
  }
}
