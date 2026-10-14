import 'package:flutter/material.dart';
import 'package:melist_core/melist_core.dart';

class WishTile extends StatelessWidget {

  final WishModel wishModel;
  final VoidCallback? onTapDelete;
  final VoidCallback? onTap;

  const WishTile({super.key, required this.wishModel, this.onTapDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(wishModel.name),
      leading: (wishModel.coverUrl != null)
          ? Image.network(wishModel.coverUrl!)
          : null,
      subtitle: Text("${wishModel.price.toString()} ₽"),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (onTapDelete != null)
            IconButton(
              onPressed: onTapDelete,
              icon: Icon(Icons.delete)
            )
        ],
      ),
      onTap: onTap
    );
  }
}
