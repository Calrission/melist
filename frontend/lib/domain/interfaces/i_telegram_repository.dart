import 'package:flutter/widgets.dart';
import 'package:melist_core/melist_core.dart';

abstract class ITelegramRepository {
  Future<void> initialize();
  UserModel getUserData();
  Brightness getBrightness();
  bool get isAvailable;
  String get initData;
}

class MockTelegramRepository implements ITelegramRepository {
  @override
  bool get isAvailable => true;

  @override
  String get initData => '';

  @override
  Future<void> initialize() {
    return Future.value();
  }

  @override
  UserModel getUserData() {
    return UserModel(
      id: 0,
      firstName: 'Test',
      lastName: 'Test',
      username: 'melist_test',
      avatarUrl:
          "https://t.me/i/userpic/320/YvKU5WJ7_k4hmztPkqukrB1-hU4tcUNurDfG18WSa-I.svg",
    );
  }

  @override
  Brightness getBrightness() => Brightness.light;
}

class UnavailableTelegramRepository implements ITelegramRepository {
  @override
  bool get isAvailable => false;

  @override
  String get initData => '';

  @override
  Future<void> initialize() => Future.value();

  @override
  UserModel getUserData() => const UserModel(id: 0);

  @override
  Brightness getBrightness() => Brightness.light;
}
