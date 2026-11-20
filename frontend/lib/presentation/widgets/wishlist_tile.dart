import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

String _giftCountLabel(int count) {
  final lastTwoDigits = count % 100;
  final lastDigit = count % 10;

  if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
    return '$count подарков';
  }
  if (lastDigit == 1) {
    return '$count подарок';
  }
  if (lastDigit >= 2 && lastDigit <= 4) {
    return '$count подарка';
  }
  return '$count подарков';
}

String _ownerLabel(WishlistModel wishlist) {
  final nickname = wishlist.ownerNickname?.trim();
  if (nickname != null && nickname.isNotEmpty) {
    return 'Владелец: $nickname';
  }
  return 'Владелец: ${wishlist.ownerId}';
}

class WishListTile extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onTapDelete;
  final bool showEdit;
  final bool showOwner;
  final VoidCallback? onTapOwner;
  final bool showFavoriteAction;
  final bool isFavorite;
  final Future<bool> Function(bool isFavorite)? onToggleFavorite;

  /// Non-null turns on the selection checkbox.
  final bool? selected;
  final ValueChanged<bool?>? onSelect;
  final List<Widget> actions;

  final WishlistModel wishlistModel;

  const WishListTile({
    super.key,
    this.onTap,
    this.onTapDelete,
    this.showEdit = true,
    this.showOwner = false,
    this.onTapOwner,
    this.showFavoriteAction = false,
    this.isFavorite = true,
    this.onToggleFavorite,
    this.selected,
    this.onSelect,
    this.actions = const [],
    required this.wishlistModel,
  });

  @override
  State<WishListTile> createState() => _WishListTileState();
}

class _WishListTileState extends State<WishListTile> {
  late bool _isFavorite = widget.isFavorite;

  @override
  void didUpdateWidget(covariant WishListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _isFavorite;
    final succeeded = await widget.onToggleFavorite?.call(wasFavorite) ?? false;
    if (!succeeded || !mounted) {
      return;
    }
    // The parent can publish the new flag through [WishListTile.isFavorite]
    // while this request is in flight. Invert the value we sent, not the
    // current one, or that update is undone and the icon flips back.
    final next = !wasFavorite;
    if (_isFavorite != next) {
      setState(() => _isFavorite = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistModel = widget.wishlistModel;
    final previewItems = wishlistModel.items.take(4).toList();
    final selected = widget.selected;
    return _Wiggle(
      enabled: selected == true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: context.palette.subText.withValues(alpha: 0.08),
          child: Ink(
            padding: EdgeInsets.only(left: 20, right: 8, top: 14, bottom: 30),
            decoration: BoxDecoration(
              color: selected == true
                  ? context.palette.accent.withValues(alpha: 0.12)
                  : context.palette.container,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: selected == true
                    ? context.palette.accent
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            wishlistModel.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.palette.accent,
                            ),
                          ),
                          if (widget.showOwner && widget.onTapOwner != null)
                            TextButton(
                              onPressed: widget.onTapOwner,
                              style: TextButton.styleFrom(
                                foregroundColor: context.palette.subText,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                _ownerLabel(wishlistModel),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Text(
                              widget.showOwner
                                  ? _ownerLabel(wishlistModel)
                                  : _giftCountLabel(wishlistModel.items.length),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final itemAction in widget.actions) itemAction,
                    if (widget.showFavoriteAction)
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: widget.onToggleFavorite == null
                            ? null
                            : _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite
                              ? context.palette.accent
                              : context.palette.subText,
                        ),
                      ),
                    if (widget.showEdit)
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: selected == null
                            ? () {
                                context.goNamed(
                                  wishlistEditGoKey,
                                  pathParameters: {
                                    'id': wishlistModel.id.toString(),
                                  },
                                );
                              }
                            : null,
                        icon: Icon(
                          MelistIcons.edit,
                          color: selected == null
                              ? context.palette.accent
                              : Colors.transparent,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  spacing: 12,
                  children: previewItems.isEmpty
                      ? List.generate(4, (_) => _WishlistItemPreview())
                      : [
                          for (final item in previewItems)
                            _WishlistItemPreview(coverUrl: item.coverUrl),
                        ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wiggle extends StatefulWidget {
  const _Wiggle({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<_Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _angle = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _Wiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      child: widget.child,
      builder: (context, child) => Transform.rotate(
        angle: widget.enabled ? _angle.value : 0,
        child: child,
      ),
    );
  }
}

class _WishlistItemPreview extends StatelessWidget {
  const _WishlistItemPreview({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: 62,
        height: 62,
        child: imageUrl == null || imageUrl.isEmpty
            ? const ColoredBox(color: Colors.white)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Colors.white),
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              ),
      ),
    );
  }
}
