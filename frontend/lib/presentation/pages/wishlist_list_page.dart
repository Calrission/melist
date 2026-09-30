import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishlistListPage extends StatefulWidget {
  const WishlistListPage({super.key});

  @override
  State<WishlistListPage> createState() => _WishlistListPageState();
}

class _WishlistListPageState extends State<WishlistListPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame((){
      context.read<WishlistListController>().loadMyWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistListController>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: (){
          context.goNamed(wishlistCreateGoKey);
        }
      ),
      body: Column(
        children: [
          Text("Виш-листы"),
          switch (controller.state) {
            ControllerState.init => LoadingWidget(),
            ControllerState.loading => LoadingWidget(),
            ControllerState.loaded => _LoadedWishlistPage(
              wishlists: controller.data!,
            ),
            ControllerState.error => ErrorPlaceholderWidget(),
          },
        ],
      ),
    );
  }
}

class _LoadedWishlistPage extends StatelessWidget {
  final List<WishlistModel> wishlists;
  const _LoadedWishlistPage({required this.wishlists});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<WishlistListController>();
    return Expanded(
      child: (wishlists.isNotEmpty)
        ? ListView.separated(
            itemCount: wishlists.length,
            separatorBuilder: (ctx, _) => SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final e = wishlists[index];
              return ListTile(
                title: Text(e.name),
                subtitle: Text("Кол-во вишей: ${e.items.length}"),
                onTap: () {
                  context.goNamed(wishlistGoKey, pathParameters: {'id': e.id.toString()});
                },
                trailing: Row(
                  spacing: 8,
                  mainAxisSize: .min,
                  children: [
                    IconButton(onPressed: (){
                      context.goNamed(
                        wishlistEditGoKey,
                        pathParameters: {'id': e.id.toString()}
                      );
                    }, icon: Icon(Icons.edit)),
                    IconButton(onPressed: (){
                      controller.deleteWishlists([e.id]);
                    }, icon: Icon(Icons.delete)),
                  ],
                ),
              );
            },
          )
        : EmptyPlaceholderWidget()
    );
  }
}