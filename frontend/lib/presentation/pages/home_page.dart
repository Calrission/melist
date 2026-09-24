import 'package:flutter/material.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
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
    context.read<ProfileController>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final telegram = context.read<ITelegramRepository>();
    final profile = context.watch<ProfileController>();
    final brightness = telegram.getBrightness();
    final user = profile.profile;
    return Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black26
          : Colors.white,
      body: (user == null)
          ? Center(child: CircularProgressIndicator())
          : ProfileWidget(userModel: user, brightness: brightness),
    );
  }
}
