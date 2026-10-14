import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/favorites_wishlist_controller.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/wish_list_tile.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';

class FavoritesWishlistPage extends StatelessWidget {
  const FavoritesWishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FavoritesWishlistController>();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: switch(controller.state) {
        ControllerState.init => LoadingWidget(),
        ControllerState.loading =>  LoadingWidget(),
        ControllerState.error => ErrorPlaceholderWidget(),
        ControllerState.loaded => _LoadedState(wishlists: controller.data!)
      },
    );
  }
}

class _LoadedState extends StatelessWidget {

  final List<WishlistModel> _wishlists;
  const _LoadedState({required this._wishlists});

  @override
  Widget build(BuildContext context) {
     return ListView.separated(
       itemBuilder: (context, index) => WishListTile(
         wishlistModel: _wishlists[index],
         onTap: () {
           context.goNamed(
             wishlistGoKey,
             pathParameters: {'id': _wishlists[index].id.toString()},
           );
         },
       ),
       separatorBuilder: (context, index) => SizedBox(height: 8),
       itemCount: _wishlists.length
     );
  }
}