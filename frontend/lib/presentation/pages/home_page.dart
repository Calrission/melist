import 'package:flutter/material.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final user = controller.profile;

    return Scaffold(
      backgroundColor: user?.theme == UiTheme.dark
          ? Colors.black26
          : Colors.white,
      body: switch(controller.state) {
        ControllerState.init => LoadingWidget(),
        ControllerState.loading => LoadingWidget(),
        ControllerState.loaded => ProfileWidget(userModel: user!),
        ControllerState.error => Center(child: Text("Error loading profile")),
      },
    );
  }
}
