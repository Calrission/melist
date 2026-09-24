import 'package:get_it/get_it.dart';
import 'package:melist/domain/models/config.dart';

Future<void> initConfigModule(GetIt getIt) async {
  const apiUrl = String.fromEnvironment('API_URL');

  final config = Config(
    apiUrl: apiUrl,
  );
  getIt.registerSingleton(config);
}
