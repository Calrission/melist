import 'package:flutter/widgets.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class ProfileController extends BaseController<UserModel?> {
  final IProfileRepository _repository;
  final ThemeController? _theme;
  ProfileController({required this._repository, this._theme});

  UserModel? get profile => data;

  static ProfileController of(BuildContext context) {
    return context.read<ProfileController>();
  }

  Future<void> loadProfile() async {
    emit(ControllerState.loading);
    try {
      _apply(await _repository.getMyProfile());
    } on Object catch (e) {
      error = e;
    }
  }

  Future<void> updateBirthday(DateTime newBirthday) async {
    await updateProfile(PatchProfileBody(birthday: newBirthday));
  }

  Future<void> clearBirthday() async {
    await updateProfile(const PatchProfileBody(birthday: null));
  }

  Future<void> updateTheme(UiTheme theme) async {
    await updateProfile(PatchProfileBody(theme: theme));
  }

  Future<void> updateNickname(String nickname) async {
    await updateProfile(PatchProfileBody(nickname: nickname));
  }

  Future<void> updateProfile(PatchProfileBody body) async {
    _apply(await _repository.patchMyProfile(body));
  }

  void _apply(UserModel user) {
    data = user;
    _theme?.applyFromProfile(user.theme);
  }
}
