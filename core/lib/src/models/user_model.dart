import 'enums.dart';
import 'model_codec.dart';

/// Row of `users`. [id] is the Telegram user id.
class UserModel {
  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarUrl,
    this.birthday,
    this.theme = UiTheme.system,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: requireInt(json['id'], 'id'),
      firstName: optionalString(json['firstName']),
      lastName: optionalString(json['lastName']),
      username: optionalString(json['username']),
      avatarUrl: optionalString(json['avatarUrl']),
      birthday: optionalDateTime(json['birthday'], 'birthday'),
      theme: json['theme'] == null
          ? UiTheme.system
          : UiTheme.fromName(json['theme']),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
      updatedAt: optionalDateTime(json['updatedAt'], 'updatedAt'),
    );
  }

  /// Builds from a PostgreSQL row (`snake_case` column names).
  factory UserModel.fromRow(Map<String, dynamic> row) {
    return UserModel(
      id: requireInt(row['id'], 'id'),
      firstName: optionalString(row['first_name']),
      lastName: optionalString(row['last_name']),
      username: optionalString(row['username']),
      avatarUrl: optionalString(row['avatar_url']),
      birthday: optionalDateTime(row['birthday'], 'birthday'),
      theme: row['theme'] == null
          ? UiTheme.system
          : UiTheme.fromName(row['theme']),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
      updatedAt: optionalDateTime(row['updated_at'], 'updatedAt'),
    );
  }

  final int id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarUrl;
  final DateTime? birthday;
  final UiTheme theme;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'avatarUrl': avatarUrl,
        'birthday': birthday == null ? null : dateOnly(birthday!),
        'theme': theme.name,
        'createdAt': isoOrNull(createdAt),
        'updatedAt': isoOrNull(updatedAt),
      };
}
