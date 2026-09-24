import 'package:melist/di/api_multi_provider.dart';
import 'package:melist/di/config_provider.dart';
import 'package:melist/di/telegram_provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> appProviders() => [
  ConfigProvider.provider,
  TelegramProvider.provider,
  ...ApiMultiProvider.providers,
];
