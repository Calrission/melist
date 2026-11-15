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
    Object? nickname = unset,
    String? theme,
  }) async {
    final hasBirthday = !identical(birthday, unset);
    final hasNickname = !identical(nickname, unset);
    if (!hasBirthday && !hasNickname && theme == null) {
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
    final nicknamePatch = hasNickname ? _nickname(nickname) : null;

    await _repo.ensure(user);
    final updated = await _repo.update(
      id: user.id,
      birthday: parsedBirthday,
      clearBirthday: clearBirthday,
      nickname: nicknamePatch?.value,
      clearNickname: nicknamePatch?.clear ?? false,
      theme: parsedTheme,
    );
    if (updated == null) {
      throw const NotFoundException('User not found');
    }
    return updated;
  }

  Future<PublicProfileModel> getPublic(int id) async {
    final user = await _repo.findById(id);
    if (user == null) {
      throw const NotFoundException('User not found');
    }
    final lists = await _wishlists(_db).listPublicByOwner(id);
    if (lists.isEmpty) {
      return PublicProfileModel(user: user, wishlists: lists);
    }
    final itemsByList = await _wishlists(_db).listItemsFor([
      for (final list in lists) list.id,
    ]);
    return PublicProfileModel(
      user: user,
      wishlists: [
        for (final list in lists)
          list.copyWith(items: itemsByList[list.id] ?? const []),
      ],
    );
  }

  UiTheme _theme(String raw) {
    try {
      return UiTheme.fromName(raw.trim());
    } on FormatException {
      throw const BadRequestException('theme must be system, light or dark');
    }
  }

  _NicknamePatch _nickname(Object? value) {
    if (value == null) {
      return const _NicknamePatch(clear: true);
    }
    if (value is! String) {
      throw const BadRequestException('nickname must be a string or null');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const _NicknamePatch(clear: true);
    }
    if (trimmed.length > 100) {
      throw const BadRequestException('nickname is too long');
    }
    return _NicknamePatch(value: trimmed);
  }
}

class _NicknamePatch {
  const _NicknamePatch({this.value, this.clear = false});

  final String? value;
  final bool clear;
}
