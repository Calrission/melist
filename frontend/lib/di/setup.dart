import 'package:melist/di/api_multi_provider.dart';
import 'package:melist/di/config_provider.dart';
import 'package:melist/di/controllers_multi_provider.dart';
import 'package:melist/di/dio_provider.dart';
import 'package:melist/di/router_provider.dart';
import 'package:melist/di/talker_provider.dart';
import 'package:melist/di/telegram_provider.dart';
import 'package:melist/di/telegram_theme_provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> appProviders() => [
  ConfigProvider.provider,
  DioProvider.provider,
  TalkerProvider.provider,
  TelegramProvider.provider,
  ...ApiMultiProvider.providers,
  ...ControllersMultiProvider.providers,
  TelegramThemeProvider.provider,
  RouterProvider.provider,
];
