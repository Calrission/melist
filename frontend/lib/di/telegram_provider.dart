import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:melist/data/repository/telegram_repository.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:talker/talker.dart';

@JS('navigator.userAgent')
external String get _navigatorUserAgent;

@JS('window.Telegram')
external JSAny? get _telegramNamespace;

extension type _TelegramNamespace(JSObject _) implements JSObject {
  @JS('WebApp')
  external JSAny? get webApp;
}

class TelegramProvider {
  static SingleChildWidget get provider => Provider(
      create: (ctx) {
        final talker = ctx.read<Talker>();
        _disableClosingSwipe(talker);
        if (kDebugMode) {
          return MockTelegramRepository();
        }

        if (!_hasTelegramWebApp()) {
          _logMissingWebApp(talker);
          return UnavailableTelegramRepository();
        }
        try {
          WebApp().init();
          final repository = RealTelegramRepository();
          if (!repository.isAvailable) {
            _logMissingInitData(talker);
          }
          return repository;
        } catch (error, stackTrace) {
          talker.error('Telegram init failed', error, stackTrace);
          return UnavailableTelegramRepository();
        }
      }
  );
}

void _disableClosingSwipe(Talker talker) {
  if (!_hasTelegramWebApp()) {
    return;
  }
  try {
    WebApp().disableVerticalSwipes();
  } catch (error, stackTrace) {
    talker.error('Failed to disable Telegram vertical swipes', error, stackTrace);
  }
}

bool _hasTelegramWebApp() {
  try {
    final telegram = _telegramNamespace;
    if (telegram == null || !telegram.isA<JSObject>()) {
      return false;
    }
    return _TelegramNamespace(telegram as JSObject).webApp != null;
  } catch (_) {
    return false;
  }
}

void _logMissingWebApp(Talker talker) {
  talker.error(
    [
      'Telegram init failed: window.Telegram.WebApp is missing',
      'page: ${_read(_pageDebug)}',
      'userAgent: ${_read(() => _navigatorUserAgent)}',
      'telegramNamespace: ${_read(() => _telegramNamespace != null)}',
    ].join('\n'),
  );
}

void _logMissingInitData(Talker talker) {
  final app = WebApp();
  final lines = <String>[
    'Telegram init refused: initData is empty',
    'page: ${_read(_pageDebug)}',
    'userAgent: ${_read(() => _navigatorUserAgent)}',
    'telegramNamespace: ${_read(() => _telegramNamespace != null)}',
    'webAppObject: ${_read(() => _hasTelegramWebApp())}',
    'platform: ${_read(() => app.platform)}',
    'version: ${_read(() => app.version)}',
    'isSupported: ${_read(() => app.isSupported)}',
    'isActive: ${_read(() => app.isActive)}',
    'isExpanded: ${_read(() => app.isExpanded)}',
    'isFullscreen: ${_read(() => app.isFullscreen)}',
    'colorScheme: ${_read(() => app.colorScheme.name)}',
    'viewport: ${_read(() => '${app.viewportHeight} / stable ${app.viewportStableHeight}')}',
    'initDataLength: ${_read(() => app.initData.length)}',
    'initDataUnsafe: ${_read(() => _initDataUnsafeDebug(app))}',
  ];
  talker.error(lines.join('\n'));
}

String _pageDebug() {
  final uri = Uri.base;
  final hashKeys = uri.fragment.isEmpty
      ? ''
      : Uri.splitQueryString(uri.fragment).keys.join(',');
  return 'origin=${uri.origin} path=${uri.path} '
      'queryKeys=${uri.queryParameters.keys.join(',')} '
      'hashKeys=$hashKeys hashLength=${uri.fragment.length} '
      'hasTgWebAppData=${uri.fragment.contains('tgWebAppData')}';
}

String _initDataUnsafeDebug(WebApp app) {
  final data = app.initDataUnsafe;
  final user = data.user;
  return 'userId=${user?.id} username=${user?.username} '
      'language=${user?.languageCode} startParam=${data.startParam} '
      'authDate=${data.authDate} chatType=${data.chatType} '
      'hasQueryId=${data.queryId != null} '
      'hashLength=${data.hash.length} signatureLength=${data.signature.length}';
}

String _read(Object? Function() read) {
  try {
    return '${read()}';
  } catch (error) {
    return 'unreadable ($error)';
  }
}
