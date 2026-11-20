import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:melist/presentation/router/app_router.dart';
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
    final (:shared, :lists, :wishlist, :wishes) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = guest;

    await tester.pumpWidget(
      _host(
        profile: profile,
        shared: shared,
        lists: lists,
        wishlist: wishlist,
        wishes: wishes,
      ),
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
    final (:shared, :lists, :wishlist, :wishes) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = guest;

    await tester.pumpWidget(
      _host(
        profile: profile,
        shared: shared,
        lists: lists,
        wishlist: wishlist,
        wishes: wishes,
      ),
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
    final (:shared, :lists, :wishlist, :wishes) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = owner;

    await tester.pumpWidget(
      _host(
        profile: profile,
        shared: shared,
        lists: lists,
        wishlist: wishlist,
        wishes: wishes,
      ),
    );
    await tester.pump();

    expect(find.text('Забронировать хотелку'), findsNothing);
    expect(find.text('Снять бронь хотелки'), findsNothing);
    expect(find.byTooltip('Редактировать'), findsOneWidget);
  });

  testWidgets('the owner sees a wish saved in the catalog', (tester) async {
    final wishlists = _Wishlists(
      const WishlistModel(
        id: 3,
        ownerId: 7,
        name: 'Gifts',
        shareToken: 'token',
        items: [_freeWish],
      ),
    );
    final (:shared, :lists, :wishlist, :wishes) = _shared(wishlists);
    wishes.data = [
      WishModel(
        id: 4,
        ownerId: 7,
        name: 'Updated book',
        description: 'New text',
        updatedAt: DateTime.utc(2026, 11, 20),
      ),
    ];
    final profile = ProfileController(repository: _Profiles())..data = owner;

    await tester.pumpWidget(
      _host(
        profile: profile,
        shared: shared,
        lists: lists,
        wishlist: wishlist,
        wishes: wishes,
        initialWish: WishModel(
          id: 4,
          ownerId: 7,
          name: 'Book',
          updatedAt: DateTime.utc(2026, 11, 1),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Updated book'), findsOneWidget);
    expect(find.text('New text'), findsOneWidget);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('returning from edit shows the saved wish', (tester) async {
    final wishlists = _Wishlists(
      const WishlistModel(
        id: 3,
        ownerId: 7,
        name: 'Gifts',
        shareToken: 'token',
        items: [_freeWish],
      ),
    );
    final (:shared, :lists, :wishlist, :wishes) = _shared(wishlists);
    await shared.loadByToken('token');
    final profile = ProfileController(repository: _Profiles())..data = owner;
    const saved = WishModel(
      id: 4,
      ownerId: 7,
      name: 'Updated book',
      description: 'New text',
    );
    final router = GoRouter(
      initialLocation: '/wishes/4',
      routes: [
        GoRoute(
          path: '/wishes',
          name: wishesGoKey,
          builder: (_, _) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: ':id',
              name: wishDetailsGoKey,
              builder: (_, _) =>
                  const WishDetailsPage(wishId: 4, initialWish: _freeWish),
            ),
            GoRoute(
              path: ':id/edit',
              name: wishEditGoKey,
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(saved),
                  child: const Text('save'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileController>.value(value: profile),
          ChangeNotifierProvider<WishlistListController>.value(value: lists),
          ChangeNotifierProvider<WishlistController>.value(value: wishlist),
          ChangeNotifierProvider<WishesController>.value(value: wishes),
          ChangeNotifierProvider<SharedWishlistController>.value(value: shared),
        ],
        child: MaterialApp.router(
          theme: Palette.light().themeData,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Book'), findsOneWidget);
    await tester.tap(find.byTooltip('Редактировать'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(find.text('Updated book'), findsOneWidget);
    expect(find.text('New text'), findsOneWidget);
  });
}

({
  SharedWishlistController shared,
  WishlistListController lists,
  WishlistController wishlist,
  WishesController wishes,
})
_shared(_Wishlists wishlists) {
  final repository = _Wishes();
  final lists = WishlistListController(repository: wishlists);
  final wishlist = WishlistController(
    wishlistRepository: wishlists,
    wishRepository: repository,
    wishlistListController: lists,
  );
  final wishes = WishesController(
    repository: repository,
    wishlists: lists,
    wishlist: wishlist,
  );
  return (
    shared: SharedWishlistController(
      wishlistRepository: wishlists,
      wishRepository: repository,
      wishlists: lists,
      wishes: wishes,
    ),
    lists: lists,
    wishlist: wishlist,
    wishes: wishes,
  );
}

Widget _host({
  required ProfileController profile,
  required SharedWishlistController shared,
  required WishlistListController lists,
  required WishlistController wishlist,
  required WishesController wishes,
  WishModel initialWish = _freeWish,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileController>.value(value: profile),
      ChangeNotifierProvider<WishlistListController>.value(value: lists),
      ChangeNotifierProvider<WishlistController>.value(value: wishlist),
      ChangeNotifierProvider<WishesController>.value(value: wishes),
      ChangeNotifierProvider<SharedWishlistController>.value(value: shared),
    ],
    child: MaterialApp(
      theme: Palette.light().themeData,
      home: WishDetailsPage(wishId: 4, initialWish: initialWish),
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
