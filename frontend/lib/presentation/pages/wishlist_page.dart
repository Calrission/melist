import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.goNamed(
            wishCreateGoKey,
            pathParameters: {'id': widget.wishlistId.toString()},
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: _WishlistView(wishlistId: widget.wishlistId),
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
      return ErrorPlaceholderWidget();
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
    return Column(
      children: [
        Text(wishlist.name),
        Expanded(
          child: (wishlist.items.isEmpty)
              ? EmptyPlaceholderWidget()
              : ListView.separated(
                  itemBuilder: (ctx, index) {
                    final e = wishlist.items[index];
                    return ListTile(
                      title: Text(e.name),
                      leading: (e.coverUrl != null)
                          ? Image.network(e.coverUrl!)
                          : null,
                      subtitle: Text("${e.price.toString()} ₽"),
                      trailing: Row(
                        mainAxisSize: .min,
                        children: [
                          IconButton(
                            onPressed: (){
                              controller.deleteWish(e.id);
                            },
                            icon: Icon(Icons.delete)
                          )
                        ],
                      ),
                      onTap: () {
                        // context.goNamed(, extra: {
                        //   'wishlistId': wishlistId.toString()
                        // });
                      },
                    );
                  },
                  separatorBuilder: (ctx, index) => SizedBox(height: 8),
                  itemCount: wishlist.items.length,
                ),
        ),
      ],
    );
  }
}
