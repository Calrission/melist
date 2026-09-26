import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'presentation/my_app.dart';

void main() {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
