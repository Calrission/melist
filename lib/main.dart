import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'my_app.dart';

void main() {
  try {
    WebApp().init();
    runApp(MyApp());
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Mini App: $e');
    }
  }
}

