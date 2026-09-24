import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:melist_backend/src/auth/jwt_service.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/refresh_token_repository.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_core/melist_core.dart';

class IssuedAuthSession {
  const IssuedAuthSession({
    required this.session,
    required this.refreshToken,
    required this.refreshTokenId,
    required this.refreshTtl,
  });

  final AuthSessionModel session;
  final String refreshToken;
  final int refreshTokenId;
  final Duration refreshTtl;
}

String generateRefreshToken() {
  final bytes = Uint8List(32);
  final random = Random.secure();
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return base64Url.encode(bytes).replaceAll('=', '');
}

String hashRefreshToken(String raw) {
  return sha256.convert(utf8.encode(raw)).toString();
}

class AuthSessionService {
  AuthSessionService({
    required this.jwtService,
    required this.refreshTtl,
    required DbExecutor db,
    Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)?
    transaction,
    RefreshTokenRepository Function(DbExecutor db)? tokens,
    UserRepository Function(DbExecutor db)? users,
    String Function()? newRefreshToken,
    DateTime Function()? clock,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _tokens = tokens ?? RefreshTokenRepository.new,
       _users = users ?? UserRepository.new,
       _newRefreshToken = newRefreshToken ?? generateRefreshToken,
       _clock = clock ?? DateTime.now;

  factory AuthSessionService.fromDatabase(
    Database database, {
    required JwtService jwtService,
    required Duration refreshTtl,
  }) {
    return AuthSessionService(
      jwtService: jwtService,
      refreshTtl: refreshTtl,
      db: database,
      transaction: database.transaction,
    );
  }

  final JwtService jwtService;
  final Duration refreshTtl;
  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final RefreshTokenRepository Function(DbExecutor db) _tokens;
  final UserRepository Function(DbExecutor db) _users;
  final String Function() _newRefreshToken;
  final DateTime Function() _clock;

  Future<IssuedAuthSession> issue(UserModel user) {
    return _transaction((tx) => _issue(tx, user));
  }

  Future<IssuedAuthSession> rotate(String rawRefresh) {
    return _transaction((tx) async {
      final tokens = _tokens(tx);
      final now = _clock().toUtc();
      final current = await tokens.findByHash(hashRefreshToken(rawRefresh));
      if (current == null) {
        throw const UnauthorizedException('Invalid refresh token');
      }
      if (current.isRevoked) {
        await tokens.revokeAllForUser(current.userId, revokedAt: now);
        throw const UnauthorizedException('Invalid refresh token');
      }
      if (!current.expiresAt.toUtc().isAfter(now)) {
        await tokens.revoke(current.id, revokedAt: now);
        throw const UnauthorizedException('Invalid refresh token');
      }

      final user = await _users(tx).findById(current.userId);
      if (user == null) {
        await tokens.revoke(current.id, revokedAt: now);
        throw const UnauthorizedException('Invalid refresh token');
      }

      final issued = await _issue(tx, user);
      await tokens.revoke(
        current.id,
        revokedAt: now,
        replacedBy: issued.refreshTokenId,
      );
      return issued;
    });
  }

  Future<void> revoke(String? rawRefresh) async {
    if (rawRefresh == null || rawRefresh.isEmpty) {
      return;
    }
    final now = _clock().toUtc();
    final current = await _tokens(_db).findByHash(hashRefreshToken(rawRefresh));
    if (current == null || current.isRevoked) {
      return;
    }
    await _tokens(_db).revoke(current.id, revokedAt: now);
  }

  Future<IssuedAuthSession> _issue(DbExecutor tx, UserModel user) async {
    final raw = _newRefreshToken();
    final id = await _tokens(tx).insert(
      userId: user.id,
      tokenHash: hashRefreshToken(raw),
      expiresAt: _clock().toUtc().add(refreshTtl),
    );
    return IssuedAuthSession(
      session: AuthSessionModel(
        accessToken: jwtService.issueAccessToken(user),
        expiresIn: jwtService.accessTokenTtl.inSeconds,
        user: user,
      ),
      refreshToken: raw,
      refreshTokenId: id,
      refreshTtl: refreshTtl,
    );
  }
}
