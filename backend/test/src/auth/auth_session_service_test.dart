import 'package:melist_backend/melist_backend.dart';
import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

import '../../helpers/memory_refresh_tokens.dart';
import '../../helpers/memory_wishlists.dart';

void main() {
  const user = UserModel(
    id: 279058397,
    firstName: 'Vladislav',
    username: 'vdkfrost',
  );
  const jwtService = JwtService(secret: 'test-secret');
  final now = DateTime.utc(2026, 9, 22, 12);

  late MemoryWishlistData usersData;
  late MemoryUserRepository users;
  late MemoryRefreshTokenRepository tokens;
  late List<String> issuedRaw;
  late AuthSessionService sessions;

  setUp(() {
    usersData = MemoryWishlistData();
    users = MemoryUserRepository(usersData);
    tokens = MemoryRefreshTokenRepository();
    issuedRaw = <String>[];
    var n = 0;
    sessions = memoryAuthSessionService(
      jwtService: jwtService,
      users: users,
      tokens: tokens,
      newRefreshToken: () {
        n += 1;
        final raw = 'refresh-$n';
        issuedRaw.add(raw);
        return raw;
      },
      clock: () => now,
    );
  });

  test('hashRefreshToken is a hex SHA-256', () {
    expect(hashRefreshToken('refresh-1'), hasLength(64));
    expect(
      hashRefreshToken('refresh-1'),
      equals(hashRefreshToken('refresh-1')),
    );
    expect(
      hashRefreshToken('refresh-1'),
      isNot(equals(hashRefreshToken('refresh-2'))),
    );
  });

  group('AuthSessionService.issue', () {
    test('stores a hashed refresh token and returns a JWT', () async {
      await users.upsertTelegram(user);
      final issued = await sessions.issue(user);

      expect(issued.refreshToken, 'refresh-1');
      expect(issued.session.expiresIn, 900);
      expect(
        jwtService.verify(issued.session.accessToken).subject,
        '279058397',
      );
      expect(tokens.rows, hasLength(1));
      expect(tokens.rows.single.tokenHash, hashRefreshToken('refresh-1'));
      expect(tokens.rows.single.expiresAt, now.add(const Duration(days: 7)));
      expect(tokens.rows.single.isRevoked, isFalse);
    });
  });

  group('AuthSessionService.rotate', () {
    test('issues a new pair and revokes the previous token', () async {
      await users.upsertTelegram(user);
      final first = await sessions.issue(user);
      final second = await sessions.rotate(first.refreshToken);

      expect(second.refreshToken, 'refresh-2');
      expect(second.refreshToken, isNot(first.refreshToken));
      expect(tokens.rows, hasLength(2));
      expect(tokens.rows.first.isRevoked, isTrue);
      expect(tokens.rows.first.replacedBy, second.refreshTokenId);
      expect(tokens.rows.last.isRevoked, isFalse);
    });

    test('revokes every session when a rotated token is reused', () async {
      await users.upsertTelegram(user);
      final first = await sessions.issue(user);
      final second = await sessions.rotate(first.refreshToken);

      await expectLater(
        sessions.rotate(first.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(tokens.rows.every((row) => row.isRevoked), isTrue);

      await expectLater(
        sessions.rotate(second.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('rejects an expired token', () async {
      await users.upsertTelegram(user);
      var clock = now;
      sessions = memoryAuthSessionService(
        jwtService: jwtService,
        users: users,
        tokens: tokens,
        clock: () => clock,
        newRefreshToken: () => 'refresh-1',
      );
      final issued = await sessions.issue(user);
      clock = now.add(const Duration(days: 8));

      await expectLater(
        sessions.rotate(issued.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(tokens.rows.single.isRevoked, isTrue);
    });

    test('rejects an unknown token', () async {
      await expectLater(
        sessions.rotate('nope'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('AuthSessionService.revoke', () {
    test('is a no-op without a token', () async {
      await sessions.revoke(null);
      await sessions.revoke('');
      expect(tokens.rows, isEmpty);
    });

    test('revokes only the matching session', () async {
      await users.upsertTelegram(user);
      const other = UserModel(id: 2, firstName: 'Bob');
      await users.upsertTelegram(other);
      final first = await sessions.issue(user);
      await sessions.issue(other);
      await sessions.revoke(first.refreshToken);

      expect(tokens.rows.first.isRevoked, isTrue);
      expect(tokens.rows.last.isRevoked, isFalse);
    });
  });
}
