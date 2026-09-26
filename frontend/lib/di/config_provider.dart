import 'package:melist/domain/models/config.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ConfigProvider {

  static SingleChildWidget get provider => Provider(
    create: (ctx) => _loadConfigFromEnvironment()
  );

  static Config _loadConfigFromEnvironment() {
    const apiUrl = String.fromEnvironment('API_URL');
    return Config(
      apiUrl: apiUrl,
    );
  }
}
