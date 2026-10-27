import 'package:flutter/foundation.dart';
import 'package:melist/domain/models/config.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ConfigProvider {

  static SingleChildWidget get provider => Provider(
    create: (ctx) => _loadConfigFromEnvironment()
  );

  static Config _loadConfigFromEnvironment() {
    const apiUrl = String.fromEnvironment('API_URL');
    return Config(apiUrl: resolveApiUrl(apiUrl));
  }

  /// `API_URL=http://localhost:8080` is the dev machine. A page opened from
  /// another device must call that machine, not its own loopback.
  @visibleForTesting
  static String resolveApiUrl(String configured) {
    if (!kIsWeb || configured.isEmpty) {
      return configured;
    }
    final api = Uri.tryParse(configured);
    if (api == null || !api.hasAuthority || !_isLoopback(api.host)) {
      return configured;
    }
    final page = Uri.base;
    if (_isLoopback(page.host)) {
      return configured;
    }
    if (page.scheme == 'http') {
      return api.replace(host: page.host).toString();
    }
    return page.origin;
  }

  static bool _isLoopback(String host) {
    return host == 'localhost' || host == '127.0.0.1' || host == '[::1]';
  }
}
