import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.postFrame((){
      context.read<ProfileController>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final themeController = context.read<ThemeController>();
    final user = profileController.profile;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            FilledButton(
              onPressed: themeController.toggle,
              child: Text("TOGGLE"),
            ),
            switch (profileController.state) {
              ControllerState.init => LoadingWidget(),
              ControllerState.loading => LoadingWidget(),
              ControllerState.loaded => ProfileWidget(userModel: user!),
              ControllerState.error => Center(
                child: Text("Error loading profile"),
              ),
            },
            FilledButton(
              onPressed: () => context.goNamed(wishlistsGoKey),
              child: Text("TO LIST WISHLIST"),
            ),
            FilledButton(
              onPressed: () => context.goNamed(wishlistFavoritesGoKey),
              child: Text("TO FAVORITES"),
            ),
          ],
        ),
      ),
    );
  }
}
