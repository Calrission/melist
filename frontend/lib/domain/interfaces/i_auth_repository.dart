import 'package:melist_core/melist_core.dart';

abstract class IAuthRepository {
  Future<AuthSessionModel> login(String initData);
}