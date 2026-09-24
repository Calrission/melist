import 'package:flutter/material.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist_core/melist_core.dart';

class ProfileWidget extends StatelessWidget {

  final UserModel userModel;

  const ProfileWidget({
    super.key,
    required this.userModel
  });

  void _changeBirthday(BuildContext context) async {
    final newBirthday = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now()
    );
    if (newBirthday == null || !context.mounted) {
      return;
    }
    ProfileController.of(context).updateBirthday(newBirthday);
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ProfileController.of(context).profile!;
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
            FilledButton(
              onPressed: () => _changeBirthday(context),
              child: Text("Update Birthdate"))
          ],
        ),
      ),
    );
  }
}
