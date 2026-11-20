import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/shared_wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

const _freeWish = WishModel(id: 4, ownerId: 7, name: 'Book');

void main() {
  const guest = UserModel(id: 2, firstName: 'Bob');
  const owner = UserModel(id: 7, firstName: 'Ann');

  testWidgets('someone else books and releases the wish from its page', (
    tester,
  ) async {
    final wishlists = _Wishlists(
      const WishlistModel(
        id: 3,
        ownerId: 7,
        name: 'Gifts',
        shareToken: 'token',
        items: [_freeWish],
      ),
    );
    final (:shared, :lists) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = guest;

    await tester.pumpWidget(
      _host(profile: profile, shared: shared, lists: lists),
    );
    await tester.pump();

    expect(find.text('Забронировать хотелку'), findsOneWidget);
    await tester.tap(find.text('Забронировать хотелку'));
    await tester.pumpAndSettle();

    expect(find.text('Снять бронь хотелки'), findsOneWidget);
    expect(find.text('Зарезервировано'), findsOneWidget);

    await tester.tap(find.text('Снять бронь хотелки'));
    await tester.pumpAndSettle();

    expect(find.text('Забронировать хотелку'), findsOneWidget);
    expect(find.text('Свободно'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsNothing);
    expect(
      tester.widget<Text>(find.text('Статус')).style?.color,
      Palette.light().accent,
    );
  });

  testWidgets('a wish reserved by someone else cannot be booked', (
    tester,
  ) async {
    final wishlists = _Wishlists(
      const WishlistModel(
        id: 3,
        ownerId: 7,
        name: 'Gifts',
        shareToken: 'token',
        items: [
          WishModel(
            id: 4,
            ownerId: 7,
            name: 'Book',
            status: WishStatus.reserved,
          ),
        ],
      ),
    );
    final (:shared, :lists) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = guest;

    await tester.pumpWidget(
      _host(profile: profile, shared: shared, lists: lists),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Снять бронь хотелки'), findsNothing);
    expect(find.byType(ColorFiltered), findsOneWidget);
    final palette = Palette.light();
    expect(
      tester.widget<Text>(find.text('Статус')).style?.color,
      palette.inactive,
    );
    expect(
      tester.widget<Text>(find.text('Цена')).style?.color,
      palette.inactive,
    );
    final cover = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.text('Обложка не добавлена'),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(cover.color, palette.inactive);
  });

  testWidgets('the owner does not see a booking button', (tester) async {
    final wishlists = _Wishlists(
      const WishlistModel(
        id: 3,
        ownerId: 7,
        name: 'Gifts',
        shareToken: 'token',
        items: [_freeWish],
      ),
    );
    final (:shared, :lists) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = owner;

    await tester.pumpWidget(
      _host(profile: profile, shared: shared, lists: lists),
    );
    await tester.pump();

    expect(find.text('Забронировать хотелку'), findsNothing);
    expect(find.text('Снять бронь хотелки'), findsNothing);
    expect(find.byTooltip('Редактировать'), findsOneWidget);
  });
}

({SharedWishlistController shared, WishlistListController lists}) _shared(
  _Wishlists wishlists,
) {
  final wishes = _Wishes();
  final lists = WishlistListController(repository: wishlists);
  final wishlist = WishlistController(
    wishlistRepository: wishlists,
    wishRepository: wishes,
    wishlistListController: lists,
  );
  return (
    shared: SharedWishlistController(
      wishlistRepository: wishlists,
      wishRepository: wishes,
      wishlists: lists,
      wishes: WishesController(
        repository: wishes,
        wishlists: lists,
        wishlist: wishlist,
      ),
    ),
    lists: lists,
  );
}

Widget _host({
  required ProfileController profile,
  required SharedWishlistController shared,
  required WishlistListController lists,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileController>.value(value: profile),
      ChangeNotifierProvider<WishlistListController>.value(value: lists),
      ChangeNotifierProvider<SharedWishlistController>.value(value: shared),
    ],
    child: MaterialApp(
      theme: Palette.light().themeData,
      home: const WishDetailsPage(wishId: 4, initialWish: _freeWish),
    ),
  );
}

class _Wishlists implements IWishlistRepository {
  _Wishlists(this.wishlist);

  WishlistModel wishlist;

  @override
  Future<List<WishlistModel>> getMyWishlists() async => const [];

  @override
  Future<WishlistModel> getSharedWishlist(String token) async => wishlist;

  @override
  Future<WishModel> reserveSharedWish(String token, int wishId) async {
    final current = wishlist.items.single;
    final reserved = WishModel(
      id: current.id,
      ownerId: current.ownerId,
      name: current.name,
      status: WishStatus.reserved,
      reservedByMe: true,
    );
    wishlist = wishlist.copyWith(items: [reserved]);
    return reserved;
  }

  @override
  Future<WishModel> cancelSharedWishReservation(
    String token,
    int wishId,
  ) async {
    final current = wishlist.items.single;
    final released = WishModel(
      id: current.id,
      ownerId: current.ownerId,
      name: current.name,
    );
    wishlist = wishlist.copyWith(items: [released]);
    return released;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Wishes implements IWishRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Profiles implements IProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
