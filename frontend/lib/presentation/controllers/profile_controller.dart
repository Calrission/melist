import 'package:flutter/widgets.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class ProfileController extends BaseController<UserModel?> {

  final IProfileRepository _repository;
  ProfileController({required this._repository});

  UserModel? get profile => data;

  static ProfileController of(BuildContext context) {
    return context.read<ProfileController>();
  }

  Future<void> loadProfile() async {
    emit(ControllerState.loading);
    try {
      data = await _repository.getMyProfile();
    } on Object catch(e) {
      error = e;
    }
  }

  Future<void> updateBirthday(DateTime newBirthday) async {
    final body = PatchProfileBody(birthday: newBirthday);
    await updateProfile(body);
  }

  Future<void> updateProfile(PatchProfileBody body) async {
    emit(ControllerState.loading);
    try {
      data = await _repository.patchMyProfile(body);
    } on Object catch(e) {
      error = e;
    }
  }
}