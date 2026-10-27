import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishlistPage extends StatefulWidget {
  final int wishlistId;
  const WishlistPage({super.key, required this.wishlistId});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      final controller = context.read<WishlistController>();
      final current = controller.data;
      final ready =
          controller.state == ControllerState.loaded &&
          current?.id == widget.wishlistId;
      if (!ready) {
        controller.loadById(widget.wishlistId);
      }
    });
  }

  Future<void> _share() async {
    final controller = context.read<WishlistController>();
    WishlistShareModel? shared;
    await context.guard(() async => shared = await controller.share());
    if (!mounted || shared == null) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ShareDialog(
        share: shared!,
        name: controller.data?.name ?? '',
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text("Удалить вишлист?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("Нет"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("Да"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await context.guard(
      context.read<WishlistController>().deleteWishlist,
    );
    if (deleted && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.wishlistId.toString();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: "Редактировать",
            onPressed: () => context.goNamed(
              wishlistEditGoKey,
              pathParameters: {'id': id},
            ),
            icon: Icon(Icons.edit),
          ),
          IconButton(
            tooltip: "Поделиться",
            onPressed: _share,
            icon: Icon(Icons.share),
          ),
          IconButton(
            tooltip: "Удалить",
            onPressed: _delete,
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: _WishlistView(wishlistId: widget.wishlistId),
    );
  }
}

class _ShareDialog extends StatelessWidget {
  final WishlistShareModel share;
  final String name;
  const _ShareDialog({required this.share, required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Ссылка на вишлист"),
      content: Text("url: ${share.url}\n\ntoken: ${share.shareToken}"),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: share.url));
            if (context.mounted) {
              context.showMessage("Ссылка скопирована");
            }
          },
          child: Text("Копировать ссылку"),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: share.shareToken));
            if (context.mounted) {
              context.showMessage("Токен скопирован");
            }
          },
          child: Text("Копировать токен"),
        ),
        TextButton(
          onPressed: () {
            context.read<ITelegramRepository>().shareUrl(
              share.url,
              "Мой вишлист «$name»",
            );
          },
          child: Text("Отправить в Telegram"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Закрыть"),
        ),
      ],
    );
  }
}

class _WishlistView extends StatelessWidget {
  final int wishlistId;
  const _WishlistView({required this.wishlistId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistController>();
    final ready =
        controller.state == ControllerState.loaded &&
        controller.data?.id == wishlistId;
    if (controller.state == ControllerState.error) {
      return ErrorPlaceholderWidget(
        error: controller.error,
        onRetry: () => controller.loadById(wishlistId),
      );
    }
    if (!ready) {
      return LoadingWidget();
    }
    return _LoadedWishlistView(wishlistId: wishlistId);
  }
}

class _LoadedWishlistView extends StatelessWidget {
  final int wishlistId;
  const _LoadedWishlistView({required this.wishlistId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistController>();
    final wishlist = controller.data!;
    final id = wishlistId.toString();
    return Column(
      children: [
        Text(wishlist.name),
        if (wishlist.description != null) Text(wishlist.description!),
        Text(
          "visibility: ${wishlist.visibility.name} | color: ${wishlist.color}"
          " | token: ${wishlist.shareToken ?? '—'}",
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => context.goNamed(
                wishCreateGoKey,
                pathParameters: {'id': id},
              ),
              child: Text("Новое желание"),
            ),
            OutlinedButton(
              onPressed: () => context.goNamed(
                wishAttachGoKey,
                pathParameters: {'id': id},
              ),
              child: Text("Добавить существующее"),
            ),
          ],
        ),
        Expanded(
          child: (wishlist.items.isEmpty)
            ? EmptyPlaceholderWidget()
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  final order = controller.currentOrder;
                  order.reorder(oldIndex, newIndex);
                  controller.reorderWishes(wishlistId, order);
                },
                itemBuilder: (ctx, index) {
                  final e = wishlist.items[index];
                  return ReorderableDragStartListener(
                    key: ValueKey(e),
                    index: index,
                    child: WishTile(
                      wishModel: e,
                      onTap: () => context.pushNamed(
                        wishEditGoKey,
                        pathParameters: {'id': e.id.toString()},
                      ),
                      actions: [
                        IconButton(
                          tooltip: "Убрать из вишлиста",
                          onPressed: () => context.guard(
                            () => controller.removeWish(e.id),
                          ),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: wishlist.items.length,
              ),
        ),
      ],
    );
  }
}
