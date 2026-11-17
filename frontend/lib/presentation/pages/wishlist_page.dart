import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/reorder_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/melist_reorderable_list_view.dart';
import 'package:melist/presentation/widgets/add_elem_list_button.dart';
import 'package:melist/presentation/widgets/share_dialog.dart';
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
      builder: (dialogContext) => ShareDialog(
        title: "Ссылка на вишлист",
        url: shared!.url,
        token: shared!.shareToken,
        telegramText: "Мой вишлист «${controller.data?.name ?? ''}»",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.wishlistId.toString();
    final controller = context.watch<WishlistController>();
    final wishlist = controller.data;
    final title = wishlist != null && wishlist.id == widget.wishlistId
        ? wishlist.name
        : "";
    final ready =
        controller.state == ControllerState.loaded &&
        wishlist?.id == widget.wishlistId;
    return Scaffold(
      appBar: MelistAppBar(
        title: title,
        actions: [
          IconButton(
            onPressed: () =>
                context.goNamed(wishlistEditGoKey, pathParameters: {'id': id}),
            icon: Icon(MelistIcons.edit),
          ),
          IconButton(onPressed: _share, icon: Icon(MelistIcons.share)),
        ],
      ),
      body: controller.state == ControllerState.error
          ? ErrorPlaceholderWidget(
              error: controller.error,
              onRetry: () => controller.loadById(widget.wishlistId),
            )
          : ready
          ? _LoadedWishlistView(wishlistId: widget.wishlistId)
          : LoadingWidget(),
    );
  }
}

class _LoadedWishlistView extends StatelessWidget {
  final int wishlistId;
  const _LoadedWishlistView({required this.wishlistId});

  Future<void> _showAddWishDialog(
    BuildContext context,
    String wishlistId,
  ) async {
    final createNew = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Добавить желание"),
        content: Text("Создать новое желание или добавить существующее?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("Создать новое"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("Добавить существующее"),
          ),
        ],
      ),
    );
    if (!context.mounted || createNew == null) {
      return;
    }
    context.goNamed(
      createNew ? wishCreateGoKey : wishAttachGoKey,
      pathParameters: {'id': wishlistId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistController>();
    final wishlist = controller.data!;
    final id = wishlistId.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horPagePadding),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (wishlist.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                wishlist.description!,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
              ),
            ),
          const SizedBox(height: 16),
          AddElemListButton(
            text: "Добавить желание",
            onTap: () => _showAddWishDialog(context, id),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: (wishlist.items.isEmpty)
                ? EmptyPlaceholderWidget()
                : MelistReorderableListView(
                    onReorderItem: (oldIndex, newIndex) {
                      final order = controller.currentOrder;
                      order.reorder(oldIndex, newIndex);
                      controller.reorderWishes(wishlistId, order);
                    },
                    itemBuilder: (ctx, index) {
                      final e = wishlist.items[index];
                      return WishTile(
                        key: ValueKey(e),
                        wishModel: e,
                        onTapDelete: () =>
                            context.guard(() => controller.removeWish(e.id)),
                        onTap: () => context.pushNamed(
                          wishDetailsGoKey,
                          pathParameters: {'id': e.id.toString()},
                          extra: WishDetailsArguments(wish: e),
                        ),
                      );
                    },
                    itemCount: wishlist.items.length,
                  ),
          ),
        ],
      ),
    );
  }
}
