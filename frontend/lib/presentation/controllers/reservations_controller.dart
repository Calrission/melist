import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

/// Wishes the current user reserved (`GET /api/v1/reservations`).
class ReservationsController extends BaseController<List<WishModel>> {
  ReservationsController({required this._repository});

  final IWishRepository _repository;

  Future<void> load() async {
    emit(ControllerState.loading);
    await _fetch();
  }

  /// Reloads without replacing the current list with a spinner.
  Future<void> refresh() => _fetch(keepData: true);

  Future<void> _fetch({bool keepData = false}) async {
    try {
      data = await _repository.getMyReservations();
    } on Object catch (error) {
      if (keepData && data != null) {
        setError(error, silence: true, changeState: false);
        return;
      }
      this.error = error;
    }
  }
}
