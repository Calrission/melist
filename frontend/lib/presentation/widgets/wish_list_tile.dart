import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

class WishListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onTapDelete;
  final bool showEdit;

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
    this.selected,
    this.onSelect,
    this.actions = const [],
    required this.wishlistModel,
  });

  @override
  Widget build(BuildContext context) {
    final previewItems = wishlistModel.items.take(4).toList();
    return _Wiggle(
      enabled: selected == true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: context.palette.subText.withValues(alpha: 0.08),
          child: Ink(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
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
                          Text(
                            "${wishlistModel.items.length} подарков",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showEdit)
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
              ),
      ),
    );
  }
}
