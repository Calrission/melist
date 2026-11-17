// TalkerScreen is built on package:flutter/material.dart. The app shell uses
// package:material_ui, which supplies a different MaterialLocalizations type.
// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart' as material;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

void openTalkerLog(BuildContext context) {
  final talker = context.read<Talker>();
  final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => material.Localizations(
        locale: locale,
        delegates: const [
          material.DefaultMaterialLocalizations.delegate,
          material.DefaultWidgetsLocalizations.delegate,
          cupertino.DefaultCupertinoLocalizations.delegate,
        ],
        child: material.Theme(
          data: material.ThemeData.dark(),
          child: TalkerScreen(talker: talker),
        ),
      ),
    ),
  );
}
