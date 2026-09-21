import 'enums.dart';
import 'model_codec.dart';

/// Row of `donations`.
class DonationModel {
  const DonationModel({
    required this.id,
    required this.userId,
    required this.amountStars,
    this.telegramPaymentId,
    this.status = DonationStatus.pending,
    this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: requireInt(json['id'], 'id'),
      userId: requireInt(json['userId'], 'userId'),
      amountStars: requireInt(json['amountStars'], 'amountStars'),
      telegramPaymentId: optionalString(json['telegramPaymentId']),
      status: json['status'] == null
          ? DonationStatus.pending
          : DonationStatus.fromName(json['status']),
      createdAt: optionalDateTime(json['createdAt'], 'createdAt'),
    );
  }

  factory DonationModel.fromRow(Map<String, dynamic> row) {
    return DonationModel(
      id: requireInt(row['id'], 'id'),
      userId: requireInt(row['user_id'], 'userId'),
      amountStars: requireInt(row['amount_stars'], 'amountStars'),
      telegramPaymentId: optionalString(row['telegram_payment_id']),
      status: row['status'] == null
          ? DonationStatus.pending
          : DonationStatus.fromName(row['status']),
      createdAt: optionalDateTime(row['created_at'], 'createdAt'),
    );
  }

  final int id;
  final int userId;
  final int amountStars;
  final String? telegramPaymentId;
  final DonationStatus status;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'amountStars': amountStars,
    'telegramPaymentId': telegramPaymentId,
    'status': status.name,
    'createdAt': isoOrNull(createdAt),
  };
}
