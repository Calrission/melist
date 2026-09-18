import 'package:flutter/material.dart';

class NotTelegramErrorWidget extends StatelessWidget {
  const NotTelegramErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: .min,
          mainAxisAlignment: .center,
          children: [
            Text("This is not a Telegram Mini App")
          ],
        ),
      ),
    );
  }
}
