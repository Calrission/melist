import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:provider/provider.dart';

/// Picks one of the user's wishes to attach to [wishlistId] (4.2).
class WishPickerPage extends StatefulWidget {
  final int wishlistId;
  const WishPickerPage({super.key, required this.wishlistId});

  @override
  State<WishPickerPage> createState() => _WishPickerPageState();
}

class _WishPickerPageState extends State<WishPickerPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() => context.read<WishesController>().load(query: ''));
  }

  Future<void> _attach(int wishId) async {
    final attached = await context.guard(
      () => context.read<WishlistController>().attachWish(wishId),
    );
    if (attached && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishes = context.watch<WishesController>();
    final wishlist = context.watch<WishlistController>().data;
    final attachedIds = {...?wishlist?.items.map((e) => e.id)};
    return Scaffold(
      appBar: MelistAppBar(title: Text("Добавить существующее")),
      body: switch (wishes.state) {
        ControllerState.init || ControllerState.loading => LoadingWidget(),
        ControllerState.error => ErrorPlaceholderWidget(error: wishes.error),
        ControllerState.loaded => Builder(
          builder: (context) {
            final available = wishes.data!
                .where((e) => !attachedIds.contains(e.id))
                .toList();
            if (available.isEmpty) {
              return EmptyPlaceholderWidget();
            }
            return ListView(
              children: [
                for (final e in available)
                  WishTile(wishModel: e, onTap: () => _attach(e.id)),
              ],
            );
          },
        ),
      },
    );
  }
}
