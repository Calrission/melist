import 'package:flutter/widgets.dart';
import 'package:melist/domain/models/user_data_model.dart';

abstract class ITelegramRepository {
  Future<void> initialize();
  UserDataModel getUserData();
  Brightness getBrightness();
  bool get isAvailable;
}

class MockTelegramRepository implements ITelegramRepository {
  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() {
    return Future.value();
  }

  @override
  UserDataModel getUserData() {
    return UserDataModel(
      id: 0,
      firstName: 'Test',
      lastName: 'Test',
      username: 'melist_test',
      avatarUrl: "https://t.me/i/userpic/320/YvKU5WJ7_k4hmztPkqukrB1-hU4tcUNurDfG18WSa-I.svg"
    );
  }

  @override
  Brightness getBrightness() => Brightness.light;
}