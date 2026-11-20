import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/shared_wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/wish_booking_button.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishDetailsArguments {
  const WishDetailsArguments({required this.wish});

  final WishModel wish;
}

class WishDetailsPage extends StatefulWidget {
  const WishDetailsPage({super.key, required this.wishId, this.initialWish});

  final int wishId;
  final WishModel? initialWish;

  @override
  State<WishDetailsPage> createState() => _WishDetailsPageState();
}

class _WishDetailsPageState extends State<WishDetailsPage> {
  WishModel? _wish;
  Object? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _wish = widget.initialWish;
    if (_wish == null) {
      _loading = true;
      context.postFrame(_load);
    }
    context.postFrame(() async {
      final profileController = context.read<ProfileController>();
      if (profileController.profile == null) {
        await profileController.loadProfile();
      }
      if (!mounted) {
        return;
      }
      await _loadOwnerWishlists();
    });
  }

  Future<void> _loadOwnerWishlists() async {
    final profileId = context.read<ProfileController>().profile?.id;
    final current = _wish;
    if (profileId == null || current == null || current.ownerId != profileId) {
      return;
    }
    final wishlists = context.read<WishlistListController>();
    if (wishlists.state == ControllerState.loading) {
      return;
    }
    await wishlists.refreshMyWishlist();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wish = await context.read<IWishRepository>().getMyWishById(
        widget.wishId,
      );
      if (!mounted) return;
      setState(() {
        _wish = wish;
        _loading = false;
      });
      await _loadOwnerWishlists();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _statusLabel(WishStatus status) => switch (status) {
    WishStatus.draft => "Черновик",
    WishStatus.free => "Свободно",
    WishStatus.reserved => "Зарезервировано",
  };

  WishModel? _shownWish({
    required List<WishModel>? catalog,
    required List<WishModel>? activeItems,
    required List<WishlistModel>? lists,
    required List<WishModel>? sharedItems,
    required int? profileId,
  }) {
    final wish = _wish;
    if (wish == null) {
      return null;
    }
    if (profileId != null && wish.ownerId == profileId) {
      return _newestOwnerCopy(
        wish,
        catalog: catalog,
        activeItems: activeItems,
        lists: lists,
      );
    }
    if (sharedItems == null) {
      return wish;
    }
    for (final item in sharedItems) {
      if (item.id == wish.id) {
        return item;
      }
    }
    return wish;
  }

  /// The page is opened with a snapshot. Saving updates the catalog and the
  /// open wishlist in place, so the owner's screen follows the newest copy.
  WishModel _newestOwnerCopy(
    WishModel wish, {
    required List<WishModel>? catalog,
    required List<WishModel>? activeItems,
    required List<WishlistModel>? lists,
  }) {
    var latest = wish;
    latest = _newer(latest, catalog);
    latest = _newer(latest, activeItems);
    if (lists != null) {
      for (final wishlist in lists) {
        latest = _newer(latest, wishlist.items);
      }
    }
    return latest;
  }

  WishModel _newer(WishModel current, List<WishModel>? candidates) {
    if (candidates == null) {
      return current;
    }
    var latest = current;
    for (final candidate in candidates) {
      if (candidate.id != latest.id) {
        continue;
      }
      final currentAt = latest.updatedAt;
      final nextAt = candidate.updatedAt;
      if (currentAt != null && nextAt != null && nextAt.isAfter(currentAt)) {
        latest = candidate;
      }
    }
    return latest;
  }

  WishBooking _bookingOf(WishModel wish) {
    if (wish.reservedByMe) {
      return WishBooking.mine;
    }
    if (wish.status == WishStatus.reserved) {
      return WishBooking.taken;
    }
    return WishBooking.available;
  }

  @override
  Widget build(BuildContext context) {
    final profileId = context.watch<ProfileController>().profile?.id;
    final wish = _shownWish(
      catalog: context.watch<WishesController>().data,
      activeItems: context.watch<WishlistController>().data?.items,
      lists: context.watch<WishlistListController>().data,
      sharedItems: context.watch<SharedWishlistController>().data?.items,
      profileId: profileId,
    );
    final isOwner =
        wish != null && profileId != null && wish.ownerId == profileId;
    final booking =
        wish != null &&
            profileId != null &&
            !isOwner &&
            _error == null &&
            !_loading
        ? _bookingOf(wish)
        : null;
    return Scaffold(
      appBar: MelistAppBar(
        title: wish?.name ?? "Желание",
        actions: [
          if (isOwner)
            IconButton(
              tooltip: "Редактировать",
              icon: Icon(MelistIcons.edit),
              onPressed: () async {
                final saved = await context.pushNamed<WishModel>(
                  wishEditGoKey,
                  pathParameters: {'id': wish.id.toString()},
                );
                if (!mounted || saved == null) {
                  return;
                }
                setState(() => _wish = saved);
              },
            ),
        ],
      ),
      body: _error != null
          ? ErrorPlaceholderWidget(error: _error!, onRetry: _load)
          : _loading || wish == null
          ? const LoadingWidget()
          : _buildDetails(context, wish),
      bottomNavigationBar: booking == null || wish == null
          ? null
          : _bookingBar(context, wish, booking),
    );
  }

  Widget _bookingBar(
    BuildContext context,
    WishModel wish,
    WishBooking booking,
  ) {
    return Material(
      color: context.palette.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: WishBookingButton(
            booking: booking,
            onPressed: booking == WishBooking.taken
                ? null
                : () => context.guard(() {
                    final bookings = context.read<SharedWishlistController>();
                    return wish.reservedByMe
                        ? bookings.cancelReservation(wish.id)
                        : bookings.reserveWish(wish.id);
                  }),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WishModel wish) {
    final profileId = context.watch<ProfileController>().profile?.id;
    final isOwner = profileId != null && wish.ownerId == profileId;
    final wishlistNames =
        (context.watch<WishlistListController>().data ??
                const <WishlistModel>[])
            .where(
              (wishlist) => wishlist.items.any((item) => item.id == wish.id),
            )
            .map((wishlist) => wishlist.name)
            .join(', ');
    final taken = wishIsTakenBySomeoneElse(wish);
    final accent = taken ? context.palette.inactive : context.palette.accent;
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: wish.coverUrl == null || wish.coverUrl!.isEmpty
          ? SizedBox(
              width: double.infinity,
              height: 400,
              child: ColoredBox(
                color: accent,
                child: Center(
                  child: Text(
                    "Обложка не добавлена",
                    style: TextStyle(color: context.palette.textOnAccent),
                  ),
                ),
              ),
            )
          : Image.network(
              wish.coverUrl!,
              height: 400,
              fit: BoxFit.fitHeight,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(color: accent),
                      ),
                    ),
              errorBuilder: (context, error, stackTrace) => SizedBox(
                height: 400,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: taken
                        ? context.palette.inactive
                        : context.palette.subText,
                  ),
                ),
              ),
            ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: taken
                  ? ColorFiltered(colorFilter: wishTakenGrayscale, child: cover)
                  : cover,
            ),
          ),
          if (wish.description?.isNotEmpty ?? false)
            Text(
              wish.description!,
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: context.palette.text,
                fontSize: 12,
              ),
            ),
          if (!isOwner)
            _WishDetailField(
              label: "Статус",
              value: _statusLabel(wish.status),
              accent: accent,
            ),
          _WishDetailField(
            label: "Цена",
            value: wish.price == null ? "—" : "${wish.price} ₽",
            accent: accent,
          ),
          _WishDetailField(
            label: "Ссылка",
            value: wish.url ?? "—",
            maxLines: 1,
            accent: accent,
            onCopy: wish.url == null || wish.url!.isEmpty
                ? null
                : () => context.guard(
                    () async =>
                        Clipboard.setData(ClipboardData(text: wish.url!)),
                    success: "Ссылка скопирована",
                  ),
          ),
          if (isOwner)
            _WishDetailField(
              label: "Вишлисты",
              value: wishlistNames.isEmpty ? "—" : wishlistNames,
              accent: accent,
            ),
        ],
      ),
    );
  }
}

class _WishDetailField extends StatelessWidget {
  const _WishDetailField({
    required this.label,
    required this.value,
    required this.accent,
    this.maxLines,
    this.onCopy,
  });

  final String label;
  final String value;
  final Color accent;
  final int? maxLines;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.palette.container,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: context.palette.text),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Скопировать ссылку",
                  onPressed: onCopy,
                  icon: Icon(Icons.copy, size: 16, color: accent),
                  style: IconButton.styleFrom(
                    foregroundColor: accent,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
