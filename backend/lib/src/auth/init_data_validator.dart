import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:melist_core/melist_core.dart';

enum InitDataFailureReason { invalid, expired }

sealed class InitDataValidation {
  const InitDataValidation();
}

final class InitDataSuccess extends InitDataValidation {
  const InitDataSuccess(this.user);

  final UserModel user;
}

final class InitDataFailure extends InitDataValidation {
  const InitDataFailure(this.reason);

  final InitDataFailureReason reason;
}

class InitDataValidator {
  InitDataValidator({
    required this.botToken,
    this.maxAge = const Duration(hours: 24),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String botToken;
  final Duration maxAge;
  final DateTime Function() _clock;

  InitDataValidation validate(String initData) {
    if (initData.isEmpty) {
      return const InitDataFailure(InitDataFailureReason.invalid);
    }

    final params = Map<String, String>.from(Uri.splitQueryString(initData));
    final hash = params.remove('hash');
    if (hash == null || hash.isEmpty) {
      return const InitDataFailure(InitDataFailureReason.invalid);
    }

    final pairs =
        params.entries.map((entry) => '${entry.key}=${entry.value}').toList()
          ..sort();
    final dataCheckString = pairs.join('\n');

    final secretKey = Hmac(
      sha256,
      utf8.encode('WebAppData'),
    ).convert(utf8.encode(botToken)).bytes;
    final computedHash = Hmac(
      sha256,
      secretKey,
    ).convert(utf8.encode(dataCheckString)).toString();

    if (!_constantTimeEquals(computedHash, hash)) {
      return const InitDataFailure(InitDataFailureReason.invalid);
    }

    final authDateRaw = params['auth_date'];
    final authDateSeconds = int.tryParse(authDateRaw ?? '');
    if (authDateSeconds == null) {
      return const InitDataFailure(InitDataFailureReason.invalid);
    }

    final authDate = DateTime.fromMillisecondsSinceEpoch(
      authDateSeconds * 1000,
      isUtc: true,
    );
    if (_clock().toUtc().difference(authDate) > maxAge) {
      return const InitDataFailure(InitDataFailureReason.expired);
    }

    final user = _parseUser(params['user']);
    if (user == null) {
      return const InitDataFailure(InitDataFailureReason.invalid);
    }

    return InitDataSuccess(user);
  }

  UserModel? _parseUser(String? rawUser) {
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map) {
        return null;
      }

      final user = Map<String, dynamic>.from(decoded);
      final id = (user['id'] as num?)?.toInt();
      if (id == null) {
        return null;
      }

      return UserModel(
        id: id,
        firstName: user['first_name'] as String?,
        lastName: user['last_name'] as String?,
        username: user['username'] as String?,
        avatarUrl: user['photo_url'] as String?,
      );
    } on FormatException {
      return null;
    }
  }
}

bool _constantTimeEquals(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  final length = aBytes.length > bBytes.length ? aBytes.length : bBytes.length;
  var result = aBytes.length ^ bBytes.length;

  for (var i = 0; i < length; i++) {
    final left = i < aBytes.length ? aBytes[i] : 0;
    final right = i < bBytes.length ? bBytes[i] : 0;
    result |= left ^ right;
  }

  return result == 0;
}
