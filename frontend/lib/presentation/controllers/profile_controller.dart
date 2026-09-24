import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';

class ProfileController extends BaseController<UserModel?> {

  final IProfileRepository _repository;
  ProfileController({required this._repository});

  UserModel? get profile => data;

  Future<void> loadProfile() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyProfile();
    } on Object catch(e) {
      error = e;
    }
  }
}