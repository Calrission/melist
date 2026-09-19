import 'dart:convert';

import 'package:crypto/crypto.dart'; // добавьте в pubspec.yaml
import 'package:dart_frog/dart_frog.dart';

// Токен бота (лучше брать из .env)
const botToken = 'YOUR_BOT_TOKEN';

Future<Response> onRequest(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final initData = body['initData'] as String;

  final isValid = _validateInitData(initData, botToken);
  if (!isValid) {
    return Response.json(statusCode: 401, body: {'error': 'Invalid initData'});
  }

  // Здесь можно создать сессию или вернуть JWT
  return Response.json(body: {'ok': true});
}

bool _validateInitData(String initData, String botToken) {
  final params = Uri.splitQueryString(initData);
  final hash = params.remove('hash');
  if (hash == null) return false;

  final dataCheckString = params.entries
      .map((e) => '${e.key}=${e.value}')
      .toList()
    ..sort();
  final checkString = dataCheckString.join('\n');

  final secretKey = Hmac(sha256, utf8.encode('WebAppData'))
      .convert(utf8.encode(botToken)).bytes;
  final signature = Hmac(sha256, secretKey)
      .convert(utf8.encode(checkString)).toString();

  return signature == hash;
}