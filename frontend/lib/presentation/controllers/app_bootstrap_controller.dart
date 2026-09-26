import 'package:flutter/foundation.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';

class AppBootstrapController extends ChangeNotifier {

  final AuthSession _session;
  final ITelegramRepository _telegram;
  final bool _allowDebug;

  AppBootstrapController({
    required this._session,
    required this._telegram,
    required this._allowDebug,
  });

  var _ready = false;
  bool get ready => _ready;

  var _restoreStarted = false;
  var _disposed = false;

  Future<void> restore() async {
    if (_restoreStarted) {
      return;
    }
    _restoreStarted = true;
    await _session.restoreSession(
      initData: _telegram.initData,
      allowDebug: _allowDebug,
    );
    if (_disposed) {
      return;
    }
    _ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
