import 'package:flutter/material.dart';
import 'package:melist/di/setup.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';

import 'pages/home_page.dart';
import 'widgets/not_telegram_error_widget.dart';

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final telegram = getIt<ITelegramRepository>();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: (telegram.isAvailable)
        ? const MyHomePage()
        : const NotTelegramErrorWidget(),
    );
  }
}