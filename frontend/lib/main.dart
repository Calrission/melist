import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melist/di/setup.dart' as di;
import 'presentation/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.setup(isDebug: kDebugMode);

  try {
    runApp(MyApp());
  } catch (e) {
    debugPrint('Error initializing Mini App: $e');
  }
}
