import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:provider/provider.dart';

class ShareDialog extends StatelessWidget {
  final String title;
  final String url;
  final String? token;
  final String telegramText;

  const ShareDialog({
    super.key,
    required this.title,
    required this.url,
    this.token,
    required this.telegramText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(
        token == null ? "url: $url" : "url: $url\n\ntoken: $token",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              context.showMessage("Ссылка скопирована");
            }
          },
          child: Text("Копировать ссылку"),
        ),
        if (token != null)
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token!));
              if (context.mounted) {
                context.showMessage("Токен скопирован");
              }
            },
            child: Text("Копировать токен"),
          ),
        TextButton(
          onPressed: () {
            context.read<ITelegramRepository>().shareUrl(url, telegramText);
          },
          child: Text("Отправить в Telegram"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Закрыть"),
        ),
      ],
    );
  }
}
