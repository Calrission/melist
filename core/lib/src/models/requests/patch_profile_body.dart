import '../enums.dart';
import '../model_codec.dart';

/// Body of `PATCH /api/me`.
///
/// [birthday] and [nickname] default to [jsonOmit] (leave unchanged).
/// Pass `null` to clear. An empty [nickname] also resets it to the default.
class PatchProfileBody {
  const PatchProfileBody({
    this.birthday = jsonOmit,
    this.nickname = jsonOmit,
    this.theme,
  });

  factory PatchProfileBody.fromJson(Map<String, dynamic> json) {
    return PatchProfileBody(
      birthday: json.containsKey('birthday')
          ? optionalDateTime(json['birthday'], 'birthday')
          : jsonOmit,
      nickname: json.containsKey('nickname') ? json['nickname'] : jsonOmit,
      theme: optionalEnum(UiTheme.values, json['theme'], 'UiTheme'),
    );
  }

  final Object? birthday;
  final Object? nickname;
  final UiTheme? theme;

  Map<String, Object?> toJson() {
    return {
      if (jsonIncluded(birthday))
        'birthday': birthday == null ? null : dateOnly(birthday as DateTime),
      if (jsonIncluded(nickname)) 'nickname': nickname,
      if (theme != null) 'theme': theme!.name,
    };
  }
}
