import 'enums.dart';
import 'model_codec.dart';

/// Row of `entitlements`.
class EntitlementModel {
  const EntitlementModel({
    required this.id,
    required this.userId,
    required this.source,
    required this.expiresAt,
    this.grantedAt,
  });

  factory EntitlementModel.fromJson(Map<String, dynamic> json) {
    return EntitlementModel(
      id: requireInt(json['id'], 'id'),
      userId: requireInt(json['userId'], 'userId'),
      source: EntitlementSource.fromName(json['source']),
      grantedAt: optionalDateTime(json['grantedAt'], 'grantedAt'),
      expiresAt: requireDateTime(json['expiresAt'], 'expiresAt'),
    );
  }

  factory EntitlementModel.fromRow(Map<String, dynamic> row) {
    return EntitlementModel(
      id: requireInt(row['id'], 'id'),
      userId: requireInt(row['user_id'], 'userId'),
      source: EntitlementSource.fromName(row['source']),
      grantedAt: optionalDateTime(row['granted_at'], 'grantedAt'),
      expiresAt: requireDateTime(row['expires_at'], 'expiresAt'),
    );
  }

  final int id;
  final int userId;
  final EntitlementSource source;
  final DateTime? grantedAt;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'source': source.name,
    'grantedAt': isoOrNull(grantedAt),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}
