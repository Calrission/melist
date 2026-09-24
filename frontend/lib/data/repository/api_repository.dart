import 'package:dio/dio.dart';
import 'package:melist/data/auth/auth_session.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist_core/melist_core.dart';

class ApiRepository implements IAuthRepository, IProfileRepository {
  ApiRepository({required this.dio, required this.authSession});

  final Dio dio;
  final AuthSession authSession;

  @override
  Future<AuthSessionModel> login(AuthValidateBody body) {
    return _postSession('/auth/validate', data: body.toJson());
  }

  @override
  Future<AuthSessionModel> refresh() {
    return _postSession('/auth/refresh');
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } finally {
      authSession.clear();
    }
  }

  @override
  Future<AuthSessionModel?> restoreSession({
    required String initData,
    bool allowDebug = false,
  }) async {
    try {
      return await refresh();
    } on DioException {
      authSession.clear();
    }

    if (initData.isNotEmpty) {
      try {
        return await login(AuthValidateBody(initData: initData));
      } on DioException {
        // Fall through to debug Bearer when enabled.
      }
    }

    if (allowDebug) {
      try {
        return await _loginDebug();
      } on DioException {
        return null;
      }
    }

    return null;
  }

  Future<AuthSessionModel> _postSession(String path, {Object? data}) async {
    final response = await dio.post(path, data: data);
    return _storeSession(response.data);
  }

  Future<AuthSessionModel> _loginDebug() async {
    final response = await dio.get('/auth/debug');
    final raw = _asMap(response.data);
    final issued = AuthSessionModel(
      accessToken: raw['accessToken'] as String,
      tokenType: raw['tokenType'] as String? ?? AuthSessionModel.bearer,
      expiresIn: (raw['expiresIn'] as num?)?.toInt() ?? 0,
      user: UserModel.fromJson(_asMap(raw['user'])),
    );
    authSession.setAccessToken(issued.accessToken);
    return issued;
  }

  AuthSessionModel _storeSession(Object? data) {
    final issued = AuthSessionModel.fromJson(_asMap(data));
    authSession.setAccessToken(issued.accessToken);
    return issued;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('Expected a JSON object, got $value');
  }

  @override
  Future<UserModel> getMyProfile() async {
    final response = await dio.get('/api/me');
    final userModel = UserModel.fromJson(response.data);
    return userModel;
  }

  @override
  Future<PublicProfileModel> getPublicProfile(int profileId) {
    // TODO: implement getPublicProfile
    throw UnimplementedError();
  }

  @override
  Future<void> patchMyProfile(PatchProfileBody body) {
    // TODO: implement patchMyProfile
    throw UnimplementedError();
  }
}
