import 'package:flutter/material.dart';
import 'package:melist_core/melist_core.dart';

class ProfileWidget extends StatelessWidget {

  final UserModel userModel;

  const ProfileWidget({
    super.key,
    required this.userModel
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SelectionArea(
        child: Column(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            Text(
              'Hello, ${userModel.username}!',
              style: TextStyle(
                color: userModel.theme == UiTheme.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            if (userModel.avatarUrl != null)
              ClipOval(
                child: Image.network(
                  width: 200,
                  userModel.avatarUrl!,
                  errorBuilder: (_, _, _) => const Icon(Icons.person),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(),
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                ),
              ),
            Text(
              'id = ${userModel.id}\n'
              'firstName = ${userModel.firstName}\n'
              'lastName = ${userModel.lastName}\n'
              'avatarUrl = ${userModel.avatarUrl}\n'
              'birthday = ${userModel.birthday}',
              style: TextStyle(
                color: userModel.theme == UiTheme.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
