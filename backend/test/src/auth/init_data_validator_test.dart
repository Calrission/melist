import 'package:melist_backend/melist_backend.dart';
import 'package:test/test.dart';

import '../../helpers/init_data.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19, 8, 13);

  InitDataValidator validator({DateTime? clock}) {
    return InitDataValidator(
      botToken: testBotToken,
      clock: () => clock ?? now,
    );
  }

  group('InitDataValidator', () {
    test('accepts a signed payload and parses the Telegram user', () {
      final initData = signInitData(authDate: unixSeconds(now));

      expect(
        validator().validate(initData),
        isA<InitDataSuccess>().having(
          (result) => result.user.id,
          'user.id',
          279058397,
        ).having(
          (result) => result.user.username,
          'username',
          'vdkfrost',
        ).having(
          (result) => result.user.avatarUrl,
          'avatarUrl',
          'https://t.me/i/userpic/320/test.svg',
        ),
      );
    });

    test('rejects a tampered hash', () {
      final initData = signInitData(
        authDate: unixSeconds(now),
        hashOverride: '0' * 64,
      );

      expect(
        validator().validate(initData),
        isA<InitDataFailure>().having(
          (result) => result.reason,
          'reason',
          InitDataFailureReason.invalid,
        ),
      );
    });

    test('rejects initData older than 24 hours', () {
      final initData = signInitData(
        authDate: unixSeconds(
          now.subtract(const Duration(hours: 24, minutes: 1)),
        ),
      );

      expect(
        validator().validate(initData),
        isA<InitDataFailure>().having(
          (result) => result.reason,
          'reason',
          InitDataFailureReason.expired,
        ),
      );
    });
  });
}
