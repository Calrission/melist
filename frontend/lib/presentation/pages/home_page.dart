import 'package:flutter/material.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    context.postFrame((){
      context.read<ProfileController>().loadProfile();
    });
  }

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
