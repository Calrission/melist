import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/wishlist_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_backend/src/http/parse.dart';
import 'package:melist_core/melist_core.dart';

class ProfileService {
  ProfileService({
    required this._db,
    UserRepository Function(DbExecutor db)? users,
    WishlistRepository Function(DbExecutor db)? wishlists,
  }) : _users = users ?? UserRepository.new,
       _wishlists = wishlists ?? WishlistRepository.new;

  factory ProfileService.fromDatabase(Database database) {
    return ProfileService(db: database);
  }

  static const unset = Object();

  final DbExecutor _db;
  final UserRepository Function(DbExecutor db) _users;
  final WishlistRepository Function(DbExecutor db) _wishlists;

  UserRepository get _repo => _users(_db);

  Future<UserModel> me(AuthUser user) async {
    await _repo.ensure(user);
    final profile = await _repo.findById(user.id);
    if (profile == null) {
      throw const NotFoundException('User not found');
    }
    return profile;
  }

  Future<UserModel> update(
    AuthUser user, {
    Object? birthday = unset,
    String? theme,
  }) async {
    final hasBirthday = !identical(birthday, unset);
    if (!hasBirthday && theme == null) {
      throw const BadRequestException('No fields to update');
    }

    DateTime? parsedBirthday;
    var clearBirthday = false;
    if (hasBirthday) {
      if (birthday == null) {
        clearBirthday = true;
      } else {
        parsedBirthday = parseJsonDateOnly(birthday, 'birthday');
      }
    }

    final parsedTheme = theme == null ? null : _theme(theme);

    await _repo.ensure(user);
    final updated = await _repo.update(
      id: user.id,
      birthday: parsedBirthday,
      clearBirthday: clearBirthday,
      theme: parsedTheme,
    );
    if (updated == null) {
      throw const NotFoundException('User not found');
    }
    return updated;
  }

  Future<({UserModel user, List<WishlistModel> wishlists})> getPublic(
    int id,
  ) async {
    final user = await _repo.findById(id);
    if (user == null) {
      throw const NotFoundException('User not found');
    }
    final wishlists = await _wishlists(_db).listPublicByOwner(id);
    return (user: user, wishlists: wishlists);
  }

  UiTheme _theme(String raw) {
    try {
      return UiTheme.fromName(raw.trim());
    } on FormatException {
      throw const BadRequestException('theme must be system, light or dark');
    }
  }
}
