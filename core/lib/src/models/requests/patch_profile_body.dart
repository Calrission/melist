import '../enums.dart';
import '../model_codec.dart';

/// Body of `PATCH /api/me`.
///
/// [birthday] defaults to [jsonOmit] (leave unchanged). Pass `null` to clear.
class PatchProfileBody {
  const PatchProfileBody({this.birthday = jsonOmit, this.theme});

  factory PatchProfileBody.fromJson(Map<String, dynamic> json) {
    return PatchProfileBody(
      birthday: json.containsKey('birthday')
          ? optionalDateTime(json['birthday'], 'birthday')
          : jsonOmit,
      theme: optionalEnum(UiTheme.values, json['theme'], 'UiTheme'),
    );
  }

  final Object? birthday;
  final UiTheme? theme;

  Map<String, Object?> toJson() {
    return {
      if (jsonIncluded(birthday))
        'birthday': birthday == null ? null : dateOnly(birthday as DateTime),
      if (theme != null) 'theme': theme!.name,
    };
  }
}
