import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist_core/melist_core.dart';

import '../router/app_router.dart';

class WishListTile extends StatelessWidget {

  final VoidCallback? onTap;
  final VoidCallback? onTapDelete;

  final WishlistModel wishlistModel;

  const WishListTile({
    super.key,
    this.onTap,
    this.onTapDelete,
    required this.wishlistModel
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(wishlistModel.name),
      subtitle: Text("Кол-во вишей: ${wishlistModel.items.length}"),
      onTap: onTap,
      trailing: Row(
        spacing: 8,
        mainAxisSize: .min,
        children: [
          IconButton(
            onPressed: () {
              context.goNamed(
                wishlistEditGoKey,
                pathParameters: {'id': wishlistModel.id.toString()},
              );
            },
            icon: Icon(Icons.edit),
          ),
          if (onTapDelete != null)
            IconButton(
              onPressed: onTapDelete,
              icon: Icon(Icons.delete),
            ),
        ],
      ),
    );
  }

}