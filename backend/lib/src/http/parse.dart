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

int parsePathId(String raw, {String field = 'id'}) {
  final id = int.tryParse(raw);
  if (id == null || id <= 0) {
    throw BadRequestException('Invalid $field');
  }
  return id;
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
