import 'package:flutter/material.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist_core/melist_core.dart';

enum ProfileState { init, loading, loaded, error }

class ProfileController extends ChangeNotifier {

  final IProfileRepository _repository;
  ProfileController({required this._repository});

  ProfileState _state = ProfileState.init;
  ProfileState get state => _state;

  UserModel? _profile;
  UserModel? get profile => _profile;

  Object? _error;

  Object? get error => _error;

  Future<void> loadProfile() async {
    _state = ProfileState.loading;
    notifyListeners();

    try {
      _profile = await _repository.getMyProfile();
      _state = ProfileState.loaded;
    } on Object catch(e) {
      _error = e;
      _state = ProfileState.error;
    }

    notifyListeners();
  }
}