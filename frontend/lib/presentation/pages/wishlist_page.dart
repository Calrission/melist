import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

class WishlistPage extends StatelessWidget {

  final int wishlistId;
  const WishlistPage({super.key, required this.wishlistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          context.pushNamed(wishCreateGoKey, extra: {
            'wishlistId': wishlistId.toString()
          });
        },
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: context.pop,
                  icon: Icon(Icons.arrow_back_ios_new)
                ),
              ],
            ),
            Expanded(
              child: ChangeNotifierProvider<WishlistController>(
                child: _WishlistView(),
                create: (ctx) => WishlistController(
                    repository: ctx.read()
                )..loadById(wishlistId),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _WishlistView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistController>();
    return switch(controller.state) {
      ControllerState.init => LoadingWidget(),
      ControllerState.loading => LoadingWidget(),
      ControllerState.loaded => _LoadedWishlistView(),
      ControllerState.error => ErrorPlaceholderWidget()
    };
  }
}

class _LoadedWishlistView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<WishlistController>();
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
                  );
                },
                separatorBuilder: (ctx, index) => SizedBox(height: 8),
                itemCount: wishlist.items.length
              )
        )
      ],
    );
  }
}