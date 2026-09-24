import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

void main() {
  group('RefreshCookie.set', () {
    test('includes HttpOnly, SameSite=Lax, Path=/auth', () {
      final header = RefreshCookie.set(
        token: 'abc',
        maxAge: const Duration(days: 7),
        secure: false,
      );

      expect(header, startsWith('refresh_token=abc;'));
      expect(header, contains('Path=/auth'));
      expect(header, contains('Max-Age=604800'));
      expect(header, contains('HttpOnly'));
      expect(header, contains('SameSite=Lax'));
      expect(header, isNot(contains('Secure')));
    });

    test('adds Secure when requested', () {
      final header = RefreshCookie.set(
        token: 'abc',
        maxAge: const Duration(minutes: 1),
        secure: true,
      );

      expect(header, contains('Secure'));
    });
  });

  group('RefreshCookie.clear', () {
    test('expires the cookie with Max-Age=0', () {
      final header = RefreshCookie.clear(secure: false);

      expect(header, startsWith('refresh_token=;'));
      expect(header, contains('Max-Age=0'));
      expect(header, contains('HttpOnly'));
      expect(header, contains('Path=/auth'));
    });
  });

  group('RefreshCookie.readHeader', () {
    test('returns the refresh_token value', () {
      expect(
        RefreshCookie.readHeader('a=1; refresh_token=secret; b=2'),
        'secret',
      );
    });

    test('returns null when missing or empty', () {
      expect(RefreshCookie.readHeader(null), isNull);
      expect(RefreshCookie.readHeader(''), isNull);
      expect(RefreshCookie.readHeader('other=1'), isNull);
      expect(RefreshCookie.readHeader('refresh_token='), isNull);
    });
  });
}
