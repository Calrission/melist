import 'package:melist/domain/interfaces/i_wishlist_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class WishlistListController extends BaseController<List<WishlistModel>> {
  WishlistListController({required this._repository});

  final IWishlistRepository _repository;

  List<int>? get currentOrder => data?.map((e) => e.id).toList();

  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool _selectionMode = false;
  bool get selectionMode => _selectionMode;

  Future<void> loadMyWishlist() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyWishlists();
    } on Object catch (e) {
      error = e;
    }
  }

  Future<bool> refreshMyWishlist() async {
    try {
      data = await _repository.getMyWishlists();
      return true;
    } on Object catch (e) {
      setError(e, silence: true, changeState: false);
      return false;
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

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    await deleteWishlists(_selectedIds.toList());
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  Future<void> deleteWishlists(List<int> ids) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    await _repository.deleteBulkWishlistsByIds(ids);
    data = data!.where((item) => !ids.contains(item.id)).toList();
  }

  Future<void> reorderWishlists(List<int> order) async {
    if (state != ControllerState.loaded || data == null) {
      return;
    }
    final next = [...data!]
      ..sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
    data = next;
    try {
      await _repository.reorderWishlists(ReorderIdsBody(order: order));
    } on Object catch (e) {
      error = e;
    }
  }
}
