import 'package:melist_backend/src/http/app_exception.dart';

String? optionalJsonString(Object? value, String field) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw BadRequestException('$field must be a string');
}

DateTime parseJsonDateOnly(Object? value, String field) {
  if (value is! String) {
    throw BadRequestException('$field must be YYYY-MM-DD');
  }
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw BadRequestException('$field must be YYYY-MM-DD');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw BadRequestException('$field must be a valid date');
  }
  return date;
}

int parsePathId(String raw, {String field = 'id'}) {
  final id = int.tryParse(raw);
  if (id == null || id <= 0) {
    throw BadRequestException('Invalid $field');
  }
  return id;
}

double? optionalJsonNumber(Object? value, String field) {
  if (value == null) {
    return null;
  }
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  throw BadRequestException('$field must be a number');
}

int? optionalJsonPositiveInt(Object? value, String field) {
  if (value == null) {
    return null;
  }
  if (value is int && value > 0) {
    return value;
  }
  if (value is num && value > 0 && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw BadRequestException('$field must be a positive integer');
}

int parseQueryInt(
  String? raw,
  String field, {
  required int fallback,
  int min = 0,
  int? max,
}) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }
  final value = int.tryParse(raw);
  if (value == null || value < min || (max != null && value > max)) {
    throw BadRequestException('Invalid $field');
  }
  return value;
}

void requireMineTrue(String? raw) {
  if (raw == null || raw.isEmpty || raw == 'true' || raw == '1') {
    return;
  }
  throw const BadRequestException('mine must be true');
}

List<int> parseIntList(Object? raw, String field) {
  if (raw == null) {
    return const [];
  }
  if (raw is! List) {
    throw BadRequestException('$field must be an array of integers');
  }

  final ids = <int>[];
  for (final item in raw) {
    if (item is int && item > 0) {
      ids.add(item);
      continue;
    }
    if (item is num && item > 0 && item == item.roundToDouble()) {
      ids.add(item.toInt());
      continue;
    }
    throw BadRequestException('$field must be an array of integers');
  }
  return ids;
}
