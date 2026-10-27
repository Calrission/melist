import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist_core/melist_core.dart';

/// The user's wish catalog (`GET /api/wishes`).
class WishesController extends BaseController<List<WishModel>> {
  WishesController({
    required this._repository,
    required this._wishlists,
    required this._wishlist,
  });

  final IWishRepository _repository;
  final WishlistListController _wishlists;
  final WishlistController _wishlist;

  String _query = '';
  String get query => _query;

  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool _selectionMode = false;
  bool get selectionMode => _selectionMode;

  Future<void> load({String? query}) async {
    if (query != null) {
      _query = query;
    }
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishes(query: _query);
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> refresh() async {
    try {
      data = await _repository.getMyWishes(query: _query);
    } on Object catch (e) {
      setError(e, silence: true, changeState: false);
    }
  }

  void toggleSelectionMode() {
    _selectionMode = !_selectionMode;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelect(int id) {
    if (!_selectedIds.remove(id)) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> duplicate(int wishId) async {
    final copy = await _repository.duplicateWishById(wishId);
    data = [copy, ...?data];
  }

  Future<void> delete(int wishId) async {
    await _repository.deleteWishById(wishId);
    await _afterDelete({wishId});
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final ids = {..._selectedIds};
    await _repository.deleteBulkWishesByIds(ids.toList());
    _selectedIds.clear();
    _selectionMode = false;
    await _afterDelete(ids);
  }

  Future<void> _afterDelete(Set<int> ids) async {
    data = (data ?? const <WishModel>[])
        .where((e) => !ids.contains(e.id))
        .toList();
    _wishlist.dropWishes(ids);
    await _wishlists.refreshMyWishlist();
  }
}
