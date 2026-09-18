abstract class ITelegramRepository {
  Future<void> initialize();
  bool get isAvailable;
}

class MockTelegramRepository implements ITelegramRepository {
  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() {
    return Future.value();
  }
}