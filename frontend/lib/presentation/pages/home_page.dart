import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static GoRoute get route =>
      GoRoute(path: '/', name: 'home', builder: (_, _) => const HomePage());

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileController>().loadProfile();
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
              onPressed: () => context.pushNamed('wishlists'),
              child: Text("TO LIST WISHLIST"),
            ),
          ],
        ),
      ),
    );
  }
}
