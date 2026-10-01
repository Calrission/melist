import 'package:flutter_test/flutter_test.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

void main() {
  test('creating a wish in a wishlist refreshes both lists', () async {
    final wishlists = _Wishlists();
    final wishes = _Wishes(wishlists);
    final list = WishlistListController(repository: wishlists);
    final wishlist = WishlistController(
      wishlistRepository: wishlists,
      wishRepository: wishes,
      wishlistListController: list
    );
    final form = WishFormController(
      repository: wishes,
      wishlists: list,
      wishlist: wishlist,
    );

    await list.loadMyWishlist();
    await wishlist.loadById(8);
    expect(list.data!.single.items, isEmpty);
    expect(wishlist.data!.items, isEmpty);

    final created = await form.create(
      const CreateWishBody(name: 'Headphones'),
      8,
    );

    expect(created, isTrue);
    expect(wishes.attachedTo, 8);
    expect(list.data!.single.items.single.name, 'Headphones');
    expect(wishlist.data!.id, 8);
    expect(wishlist.data!.items.single.name, 'Headphones');
  });
}

class _Wishes implements IWishRepository {
  _Wishes(this.wishlists);

  final _Wishlists wishlists;
  int? attachedTo;

  @override
  Future<WishModel> createWish(CreateWishBody body) async {
    return WishModel(id: 5, ownerId: 1, name: body.name);
  }

  @override
  Future<WishModel> addWishToWishlist(
    int wishlistId,
    AddWishlistWishBody body,
  ) async {
    attachedTo = wishlistId;
    final wish = WishModel(id: body.wishId!, ownerId: 1, name: 'Headphones');
    wishlists.stored = wishlists.stored.copyWith(items: [wish]);
    return wish;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Wishlists implements IWishlistRepository {
  WishlistModel stored = const WishlistModel(
    id: 8,
    ownerId: 1,
    name: 'TEST',
    color: '#FFB74D',
  );

  @override
  Future<List<WishlistModel>> getMyWishlists() async => [stored];

  @override
  Future<WishlistModel> getMyWishlistById(int wishlistId) async => stored;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
