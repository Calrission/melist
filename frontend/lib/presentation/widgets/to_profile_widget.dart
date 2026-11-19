import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_profile_repository.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

const double _avatarSize = 40;
const double _arrowCircleSize = 32;

/// Bordered row that opens the wishlist owner's profile.
class ToProfileWidget extends StatefulWidget {
  final int ownerId;
  final String? fallbackName;

  const ToProfileWidget({super.key, required this.ownerId, this.fallbackName});

  @override
  State<ToProfileWidget> createState() => _ToProfileWidgetState();
}

class _ToProfileWidgetState extends State<ToProfileWidget> {
  UserModel? _owner;

  @override
  void initState() {
    super.initState();
    context.postFrame(_loadOwner);
  }

  @override
  void didUpdateWidget(covariant ToProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      _owner = null;
      context.postFrame(_loadOwner);
    }
  }

  Future<void> _loadOwner() async {
    final ownerId = widget.ownerId;
    final mine = context.read<ProfileController>().profile;
    if (mine != null && mine.id == ownerId) {
      return;
    }
    try {
      final profile = await context.read<IProfileRepository>().getPublicProfile(
        ownerId,
      );
      if (!mounted || widget.ownerId != ownerId) {
        return;
      }
      setState(() => _owner = profile.user);
    } on Object {
      // The row still opens the profile; the name stays on [fallbackName].
    }
  }

  UserModel? _resolvedOwner(UserModel? mine) {
    if (mine != null && mine.id == widget.ownerId) {
      return mine;
    }
    final owner = _owner;
    if (owner != null && owner.id == widget.ownerId) {
      return owner;
    }
    return null;
  }

  String _name(UserModel? owner) {
    final display = owner?.displayName.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }
    return widget.fallbackName?.trim() ?? '';
  }

  void _openProfile() {
    context.pushNamed(
      publicProfileGoKey,
      pathParameters: {'id': widget.ownerId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = _resolvedOwner(context.watch<ProfileController>().profile);
    final avatarUrl = owner?.avatarUrl;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: context.palette.accent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openProfile,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _OwnerAvatar(avatarUrl: avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _name(owner),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.palette.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ArrowCircle(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? avatarUrl;

  const _OwnerAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: hasUrl
            ? Image.network(
                url,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const _AvatarPlaceholder(),
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              )
            : const _AvatarPlaceholder(),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.subText.withValues(alpha: 0.2),
      child: Icon(Icons.person, color: context.palette.subText, size: 22),
    );
  }
}

class _ArrowCircle extends StatelessWidget {
  const _ArrowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _arrowCircleSize,
      height: _arrowCircleSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        MelistIcons.arrowRight,
        color: context.palette.textOnAccent,
        size: 16,
      ),
    );
  }
}
