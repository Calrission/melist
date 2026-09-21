import 'dart:convert';

import 'package:crypto/crypto.dart';

const testBotToken = '123456:TEST_BOT_TOKEN';

const testUserJson =
    '{"id":279058397,"first_name":"Vladislav","last_name":"Kibenko",'
    '"username":"vdkfrost","photo_url":"https://t.me/i/userpic/320/test.svg"}';

String signInitData({
  required int authDate,
  String userJson = testUserJson,
  String? hashOverride,
  String botToken = testBotToken,
}) {
  final params = {
    'auth_date': '$authDate',
    'query_id': 'AAEtestquery',
    'user': userJson,
  };
  final pairs =
      params.entries.map((entry) => '${entry.key}=${entry.value}').toList()
        ..sort();
  final dataCheckString = pairs.join('\n');
  final secretKey = Hmac(
    sha256,
    utf8.encode('WebAppData'),
  ).convert(utf8.encode(botToken)).bytes;
  final hash =
      hashOverride ??
      Hmac(sha256, secretKey).convert(utf8.encode(dataCheckString)).toString();

  return [
    'auth_date=$authDate',
    'query_id=AAEtestquery',
    'user=${Uri.encodeQueryComponent(userJson)}',
    'hash=$hash',
  ].join('&');
}

int unixSeconds(DateTime dateTime) {
  return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
}
