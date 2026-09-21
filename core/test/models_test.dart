import 'package:melist_core/melist_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthSessionModel', () {
    test('fromJson / toJson round-trip for validate body', () {
      final json = {
        'accessToken': 'jwt-token',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'id': 279058397,
          'firstName': 'Vladislav',
          'lastName': 'Kibenko',
          'username': 'vdkfrost',
          'avatarUrl': 'https://t.me/i/userpic/320/test.svg',
        },
      };

      final session = AuthSessionModel.fromJson(json);

      expect(session.accessToken, 'jwt-token');
      expect(session.tokenType, AuthSessionModel.bearer);
      expect(session.expiresIn, 3600);
      expect(session.ttl, const Duration(hours: 1));
      expect(session.user.id, 279058397);
      expect(session.user.firstName, 'Vladislav');
      expect(session.user.avatarUrl, 'https://t.me/i/userpic/320/test.svg');
      expect(session.toJson(), json);
    });

    test('rejects a missing user object', () {
      expect(
        () => AuthSessionModel.fromJson({
          'accessToken': 'jwt',
          'tokenType': 'Bearer',
          'expiresIn': 3600,
        }),
        throwsFormatException,
      );
    });
  });

  group('UserModel', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 42,
        'firstName': 'Ann',
        'lastName': 'Lee',
        'username': 'ann',
        'avatarUrl': 'https://t.me/i/userpic/320/a.svg',
        'birthday': '1990-05-12',
        'theme': 'dark',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.theme, UiTheme.dark);
      expect(user.birthday, DateTime.parse('1990-05-12'));
      expect(user.toJson()['birthday'], '1990-05-12');
      expect(user.toJson()['theme'], 'dark');
    });

    test('fromRow maps snake_case columns', () {
      final user = UserModel.fromRow({
        'id': 1,
        'first_name': 'Ann',
        'last_name': null,
        'username': 'ann',
        'avatar_url': null,
        'birthday': DateTime.utc(1990, 5, 12),
        'theme': 'light',
        'created_at': DateTime.utc(2026, 1, 1),
        'updated_at': DateTime.utc(2026, 1, 1),
      });

      expect(user.firstName, 'Ann');
      expect(user.theme, UiTheme.light);
      expect(user.birthday, DateTime.utc(1990, 5, 12));
    });

    test('defaults theme to system', () {
      final user = UserModel.fromJson({'id': 1});

      expect(user.theme, UiTheme.system);
      expect(user.birthday, isNull);
    });
  });

  group('WishModel', () {
    test('nullable price and url, default visibility and status', () {
      final wish = WishModel.fromJson({
        'id': 10,
        'ownerId': 1,
        'name': 'Headphones',
      });

      expect(wish.price, isNull);
      expect(wish.url, isNull);
      expect(wish.visibility, WishVisibility.public);
      expect(wish.status, WishStatus.free);
    });

    test('fromRow maps copied_from and cover_url', () {
      final wish = WishModel.fromRow({
        'id': 2,
        'owner_id': 1,
        'name': 'Book',
        'price': '19.90',
        'url': null,
        'description': 'hardcover',
        'cover_url': 'https://img/book.png',
        'visibility': 'private',
        'status': 'reserved',
        'copied_from': 9,
      });

      expect(wish.price, closeTo(19.90, 0.001));
      expect(wish.coverUrl, 'https://img/book.png');
      expect(wish.visibility, WishVisibility.private);
      expect(wish.status, WishStatus.reserved);
      expect(wish.copiedFrom, 9);
    });
  });

  group('WishlistModel', () {
    test('replaces isPublic with visibility and index with position', () {
      final list = WishlistModel.fromJson({
        'id': 3,
        'ownerId': 1,
        'name': 'Birthday',
        'color': '#FFB74D',
        'visibility': 'public',
        'position': 2,
        'shareToken': 'abc',
        'items': [
          {'id': 10, 'ownerId': 1, 'name': 'Headphones'},
        ],
      });

      expect(list.visibility, WishlistVisibility.public);
      expect(list.position, 2);
      expect(list.color, '#FFB74D');
      expect(list.items, hasLength(1));
      expect(list.items.first.name, 'Headphones');
      expect(list.toJson()['visibility'], 'public');
    });

    test('fromRow does not include items', () {
      final list = WishlistModel.fromRow({
        'id': 3,
        'owner_id': 1,
        'name': 'Birthday',
        'description': null,
        'color': '#FFB74D',
        'visibility': 'draft',
        'position': 0,
        'share_token': null,
      });

      expect(list.items, isEmpty);
      expect(list.visibility, WishlistVisibility.draft);
    });
  });

  group('join and billing models', () {
    test('FavoriteModel fromRow', () {
      final favorite = FavoriteModel.fromRow({
        'user_id': 1,
        'wishlist_id': 3,
        'position': 4,
        'added_at': DateTime.utc(2026, 3, 1),
      });

      expect(favorite.toJson()['wishlistId'], 3);
      expect(favorite.position, 4);
    });

    test('EntitlementModel and DonationModel', () {
      final entitlement = EntitlementModel.fromJson({
        'id': 1,
        'userId': 1,
        'source': 'ad',
        'expiresAt': '2026-12-01T00:00:00.000Z',
      });
      final donation = DonationModel.fromRow({
        'id': 2,
        'user_id': 1,
        'amount_stars': 100,
        'telegram_payment_id': 'tx-1',
        'status': 'paid',
      });

      expect(entitlement.source, EntitlementSource.ad);
      expect(donation.status, DonationStatus.paid);
      expect(donation.amountStars, 100);
    });
  });

  group('enums', () {
    test('reject unknown values', () {
      expect(() => UiTheme.fromName('neon'), throwsFormatException);
      expect(() => WishStatus.fromName(null), throwsFormatException);
    });
  });
}
