import 'package:flutter/material.dart';
import 'package:melist/di/setup.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    final telegram = getIt<ITelegramRepository>();
    final userData = telegram.getUserData();
    final brightness = telegram.getBrightness();

    return Scaffold(
      backgroundColor: brightness == Brightness.dark ? Colors.black26 : Colors.white,
      body: Center(
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            children: [
              Text(
                'Hello, ${userData.username}!',
                style: TextStyle(
                  color: brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              if (userData.avatarUrl != null)
                ClipOval(
                  child: Image.network(
                    width: 200,
                    userData.avatarUrl!,
                    errorBuilder: (_, _, _) => const Icon(Icons.person),
                    loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const CircularProgressIndicator(),
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  ),
                ),
              Text(
                'id = ${userData.id}\n'
                'firstName = ${userData.firstName}\n'
                'lastName = ${userData.lastName}\n'
                'avatarUrl = ${userData.avatarUrl}',
                style: TextStyle(
                  color: brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}