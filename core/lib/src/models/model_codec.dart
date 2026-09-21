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

/// Sentinel for PATCH: the field is omitted from JSON (leave unchanged).
/// Distinct from `null`, which clears a nullable field.
const jsonOmit = Object();

bool jsonIncluded(Object? value) => !identical(value, jsonOmit);

Map<String, dynamic> requireMap(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Expected object for $field, got $value');
}

List<int> requireIntList(Object? raw, String field) {
  if (raw is! List) {
    throw FormatException('Expected array of integers for $field, got $raw');
  }
  return [for (final item in raw) requireInt(item, field)];
}

List<int> optionalIntList(Object? raw, String field) {
  return raw == null ? const [] : requireIntList(raw, field);
}

/// Maps a PostgreSQL enum / JSON string onto a Dart enum by [Enum.name].
T decodeEnum<T extends Enum>(List<T> values, Object? raw, String typeName) {
  if (raw is T) {
    return raw;
  }
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
  }
  throw FormatException('Unknown $typeName: $raw');
}

T? optionalEnum<T extends Enum>(
  List<T> values,
  Object? raw,
  String typeName,
) {
  if (raw == null) {
    return null;
  }
  return decodeEnum(values, raw, typeName);
}
