import 'package:melist_backend/src/auth/auth_user.dart';
import 'package:melist_backend/src/data/database.dart';
import 'package:melist_backend/src/data/user_repository.dart';
import 'package:melist_backend/src/data/wish_repository.dart';
import 'package:melist_backend/src/http/app_exception.dart';
import 'package:melist_core/melist_core.dart';

class WishService {
  WishService({
    required DbExecutor db,
    Future<R> Function<R>(
      Future<R> Function(DbExecutor tx) action,
    )?
    transaction,
    WishRepository Function(DbExecutor db)? wishes,
    UserRepository Function(DbExecutor db)? users,
  }) : _db = db,
       _transaction = transaction ?? (<R>(action) => action(db)),
       _wishes = wishes ?? WishRepository.new,
       _users = users ?? UserRepository.new;

  factory WishService.fromDatabase(Database database) {
    return WishService(db: database, transaction: database.transaction);
  }

  final DbExecutor _db;
  final Future<R> Function<R>(Future<R> Function(DbExecutor tx) action)
  _transaction;
  final WishRepository Function(DbExecutor db) _wishes;
  final UserRepository Function(DbExecutor db) _users;

  WishRepository get _repo => _wishes(_db);

  static const unset = Object();
  static const defaultLimit = 50;
  static const maxLimit = 100;
  static const _maxNameLength = 255;

  Future<List<WishModel>> listMine(
    AuthUser user, {
    String? query,
    int limit = defaultLimit,
    int offset = 0,
  }) {
    if (limit < 1 || limit > maxLimit) {
      throw const BadRequestException('limit must be between 1 and 100');
    }
    if (offset < 0) {
      throw const BadRequestException('offset must be >= 0');
    }

    final parsedQuery = _searchQuery(query);
    return _repo.listByOwner(
      ownerId: user.id,
      query: parsedQuery,
      limit: limit,
      offset: offset,
    );
  }

  Future<WishModel> getById(AuthUser user, int id) {
    return _requireOwned(user.id, id);
  }

  Future<WishModel> create(
    AuthUser user, {
    required String name,
    double? price,
    String? url,
    String? description,
    String? coverUrl,
    String? status,
  }) {
    final parsedName = _requireName(name);
    final parsedPrice = _optionalPrice(price);
    final parsedUrl = _optionalText(url);
    final parsedDescription = _optionalText(description);
    final parsedCoverUrl = _optionalText(coverUrl);
    final parsedStatus = _status(status);

    return _transaction((tx) async {
      await _users(tx).ensure(user);
      return _wishes(tx).insert(
        ownerId: user.id,
        name: parsedName,
        price: parsedPrice,
        url: parsedUrl,
        description: parsedDescription,
        coverUrl: parsedCoverUrl,
        status: parsedStatus,
      );
    });
  }

  Future<WishModel> update(
    AuthUser user,
    int id, {
    String? name,
    Object? price = unset,
    Object? url = unset,
    Object? description = unset,
    Object? coverUrl = unset,
    String? status,
  }) async {
    final hasPrice = !identical(price, unset);
    final hasUrl = !identical(url, unset);
    final hasDescription = !identical(description, unset);
    final hasCoverUrl = !identical(coverUrl, unset);

    if (name == null &&
        !hasPrice &&
        !hasUrl &&
        !hasDescription &&
        !hasCoverUrl &&
        status == null) {
      throw const BadRequestException('No fields to update');
    }

    final parsedName = name == null ? null : _requireName(name);
    final parsedStatus = status == null
        ? null
        : _status(status, required: true);

    final pricePatch = hasPrice ? _nullablePrice(price) : null;
    final urlPatch = hasUrl ? _nullableText(url, 'url') : null;
    final descriptionPatch = hasDescription
        ? _nullableText(description, 'description')
        : null;
    final coverUrlPatch = hasCoverUrl
        ? _nullableText(coverUrl, 'coverUrl')
        : null;

    final updated = await _repo.update(
      id: id,
      ownerId: user.id,
      name: parsedName,
      price: pricePatch?.value,
      clearPrice: pricePatch?.clear ?? false,
      url: urlPatch?.value,
      clearUrl: urlPatch?.clear ?? false,
      description: descriptionPatch?.value,
      clearDescription: descriptionPatch?.clear ?? false,
      coverUrl: coverUrlPatch?.value,
      clearCoverUrl: coverUrlPatch?.clear ?? false,
      status: parsedStatus,
    );
    if (updated != null) {
      return updated;
    }
    await _requireOwned(user.id, id);
    throw const NotFoundException();
  }

  Future<void> deleteOne(AuthUser user, int id) async {
    final deleted = await _repo.delete(id: id, ownerId: user.id);
    if (deleted > 0) {
      return;
    }
    await _requireOwned(user.id, id);
  }

  Future<void> deleteMany(AuthUser user, List<int> ids) async {
    final unique = _uniqueIds(ids);
    if (unique.isEmpty) {
      throw const BadRequestException('ids must not be empty');
    }

    final deleted = await _repo.deleteMany(ids: unique, ownerId: user.id);
    if (deleted != unique.length) {
      throw const NotFoundException('Some wishes were not found');
    }
  }

  Future<WishModel> duplicate(AuthUser user, int id) async {
    final copied = await _repo.duplicate(id: id, ownerId: user.id);
    if (copied != null) {
      return copied;
    }
    await _requireOwned(user.id, id);
    throw const NotFoundException();
  }

  Future<WishModel> _requireOwned(int ownerId, int id) async {
    final wish = await _repo.findById(id);
    if (wish == null) {
      throw const NotFoundException('Wish not found');
    }
    if (wish.ownerId != ownerId) {
      throw const ForbiddenException();
    }
    return wish;
  }

  String? _searchQuery(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value
        .replaceAll('!', '!!')
        .replaceAll('%', '!%')
        .replaceAll('_', '!_');
  }

  String? _optionalText(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String _requireName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const BadRequestException('name is required');
    }
    if (name.length > _maxNameLength) {
      throw const BadRequestException('name is too long');
    }
    return name;
  }

  double? _optionalPrice(double? price) {
    if (price == null) {
      return null;
    }
    if (price.isNaN || price.isInfinite || price < 0) {
      throw const BadRequestException('price must be a non-negative number');
    }
    return price;
  }

  _TextPatch _nullableText(Object? value, String field) {
    if (value == null) {
      return const _TextPatch(clear: true);
    }
    if (value is! String) {
      throw BadRequestException('$field must be a string or null');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const _TextPatch(clear: true);
    }
    return _TextPatch(value: trimmed);
  }

  _PricePatch _nullablePrice(Object? value) {
    if (value == null) {
      return const _PricePatch(clear: true);
    }
    if (value is! num) {
      throw const BadRequestException('price must be a non-negative number');
    }
    final parsed = value.toDouble();
    if (parsed.isNaN || parsed.isInfinite || parsed < 0) {
      throw const BadRequestException('price must be a non-negative number');
    }
    return _PricePatch(value: parsed);
  }

  WishStatus _status(String? raw, {bool required = false}) {
    if (raw == null || raw.trim().isEmpty) {
      if (required) {
        throw const BadRequestException('status is required');
      }
      return WishStatus.free;
    }
    try {
      return WishStatus.fromName(raw.trim());
    } on FormatException {
      throw const BadRequestException(
        'status must be draft, free or reserved',
      );
    }
  }

  List<int> _uniqueIds(List<int> ids) {
    final seen = <int>{};
    final unique = <int>[];
    for (final id in ids) {
      if (seen.add(id)) {
        unique.add(id);
      }
    }
    return unique;
  }
}

class _TextPatch {
  const _TextPatch({this.value, this.clear = false});

  final String? value;
  final bool clear;
}

class _PricePatch {
  const _PricePatch({this.value, this.clear = false});

  final double? value;
  final bool clear;
}
