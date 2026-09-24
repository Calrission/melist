import 'package:flutter/material.dart';
import 'package:melist/di/setup.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:melist_core/melist_core.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final telegram = getIt<ITelegramRepository>();
  final profile = getIt<IProfileRepository>();
  UserModel? user;

  @override
  void initState() {
    super.initState();

    profile.getMyProfile().then((value){
      setState(() {
        user = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = telegram.getBrightness();
    return Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black26
          : Colors.white,
      body: (user == null)
          ? Center(child: CircularProgressIndicator())
          : ProfileWidget(userModel: user!, brightness: brightness)
    );
  }
}
