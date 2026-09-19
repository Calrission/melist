int requireInt(Object? value, String field) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.parse(value);
  }
  throw FormatException('Expected int for $field, got $value');
}

int? optionalInt(Object? value, String field) {
  return value == null ? null : requireInt(value, field);
}

double requireDouble(Object? value, String field) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    throw FormatException('Expected number for $field, got null');
  }
  return double.parse(value.toString());
}

double? optionalDouble(Object? value, String field) {
  return value == null ? null : requireDouble(value, field);
}

String requireString(Object? value, String field) {
  if (value is String) {
    return value;
  }
  throw FormatException('Expected string for $field, got $value');
}

String? optionalString(Object? value) {
  return value as String?;
}

DateTime requireDateTime(Object? value, String field) {
  final parsed = optionalDateTime(value, field);
  if (parsed == null) {
    throw FormatException('Expected DateTime for $field, got $value');
  }
  return parsed;
}

DateTime? optionalDateTime(Object? value, String field) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Expected DateTime for $field, got $value');
}

String dateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String? isoOrNull(DateTime? value) => value?.toUtc().toIso8601String();
