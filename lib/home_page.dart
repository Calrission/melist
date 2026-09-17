import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final webApp = WebApp();
    return Scaffold(
      body: Text(
          'Hello, ${webApp.initDataUnsafe.user?.firstName ?? "there"}'
      ),
    );
  }
}