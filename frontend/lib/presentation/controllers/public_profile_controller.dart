import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

/// Another user's profile with public wishlists (`GET /api/v1/users/{id}`).
class PublicProfileController extends BaseController<PublicProfileModel> {
  PublicProfileController({required this._repository});

  final IProfileRepository _repository;

  Future<void> loadById(int userId) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getPublicProfile(userId);
    } on Object catch (e) {
      error = e;
    }
  }
}
