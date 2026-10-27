import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/domain/share_token.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/deep_link_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.postFrame((){
      context.read<ProfileController>().loadProfile();
      final token = context.read<DeepLinkController>().consumeSharedToken();
      if (token != null) {
        _openShared(token);
      }
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _openShared(String token) {
    context.pushNamed(sharedWishlistGoKey, pathParameters: {'token': token});
  }

  void _openByInput() {
    final token = parseShareToken(_tokenController.text);
    if (token == null) {
      context.showMessage("Введите токен или ссылку");
      return;
    }
    _openShared(token);
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.profile;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            switch (profileController.state) {
              ControllerState.init => LoadingWidget(),
              ControllerState.loading => LoadingWidget(),
              ControllerState.loaded => ProfileWidget(userModel: user!),
              ControllerState.error => ErrorPlaceholderWidget(
                error: profileController.error,
                onRetry: profileController.loadProfile,
              ),
            },
            FilledButton(
              onPressed: () => context.goNamed(wishlistsGoKey),
              child: Text("МОИ ВИШЛИСТЫ"),
            ),
            FilledButton(
              onPressed: () => context.goNamed(wishesGoKey),
              child: Text("МОИ ЖЕЛАНИЯ"),
            ),
            FilledButton(
              onPressed: () => context.goNamed(wishlistFavoritesGoKey),
              child: Text("ИЗБРАННОЕ"),
            ),
            FilledButton(
              onPressed: () => context.goNamed(subscriptionsGoKey),
              child: Text("ПОДПИСКИ"),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      hintText: 'Токен или ссылка на вишлист',
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _openByInput,
                  child: Text("Открыть"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
