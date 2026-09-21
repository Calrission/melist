import '../model_codec.dart';

/// Body of `POST /auth/validate`.
class AuthValidateBody {
  const AuthValidateBody({required this.initData});

  factory AuthValidateBody.fromJson(Map<String, dynamic> json) {
    return AuthValidateBody(
      initData: requireString(json['initData'], 'initData'),
    );
  }

  final String initData;

  Map<String, Object?> toJson() => {'initData': initData};
}
