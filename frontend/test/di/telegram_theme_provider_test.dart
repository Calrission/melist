import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melist/di/telegram_theme_provider.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('system theme follows the current Telegram brightness', (
    tester,
  ) async {
    final telegram = _Telegram();
    await tester.pumpWidget(_app(telegram));
    await tester.pump();

    expect(telegram.initializeCalls, 1);
    expect(find.text('dark'), findsOneWidget);

    telegram.brightness.add(Brightness.light);
    await tester.pump();
    await tester.pump();

    expect(find.text('light'), findsOneWidget);
  });
}

class _Telegram implements ITelegramRepository {
  final brightness = StreamController<Brightness>.broadcast();
  var initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Brightness getBrightness() => Brightness.dark;

  @override
  Stream<Brightness> get onBrightnessChanged => brightness.stream;

  @override
  bool get isAvailable => true;

  @override
  String get initData => '';

  @override
  String? get startParam => null;

  @override
  void shareUrl(String url, String text) {}

  @override
  UserModel getUserData() => const UserModel(id: 0);

  @override
  void dispose() {}
}

Widget _app(_Telegram telegram) {
  return MultiProvider(
    providers: [
      Provider<ITelegramRepository>.value(value: telegram),
      ChangeNotifierProvider(create: (_) => ThemeController()),
      TelegramThemeProvider.provider,
    ],
    child: Builder(
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Text(context.watch<ThemeController>().theme.name),
        );
      },
    ),
  );
}
