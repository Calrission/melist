import 'package:dio/dio.dart';
import 'package:melist/domain/interfaces/i_auth_repository.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist_core/melist_core.dart';

class ApiRepository implements IAuthRepository, IProfileRepository {
  ApiRepository({required this.dio});

  final Dio dio;

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
    await dio.post('/auth/logout');
  }

  Future<AuthSessionModel> _postSession(String path, {Object? data}) async {
    final response = await dio.post(path, data: data);
    return _parseSession(response.data);
  }

  @override
  Future<AuthSessionModel> loginDebug() async {
    final response = await dio.get('/auth/debug');
    final raw = _asMap(response.data);
    return AuthSessionModel(
      accessToken: raw['accessToken'] as String,
      tokenType: raw['tokenType'] as String? ?? AuthSessionModel.bearer,
      expiresIn: (raw['expiresIn'] as num?)?.toInt() ?? 0,
      user: UserModel.fromJson(_asMap(raw['user'])),
    );
  }

  AuthSessionModel _parseSession(Object? data) {
    return AuthSessionModel.fromJson(_asMap(data));
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
