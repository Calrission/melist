import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/theme_controller.dart';
import 'package:melist/presentation/controllers/wishlist_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ControllersMultiProvider {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<ProfileController>(
      create: (ctx) => ProfileController(repository: ctx.read())..loadProfile()
    ),
    ChangeNotifierProvider<ThemeController>(
      create: (ctx) => ThemeController()
    ),
    ChangeNotifierProvider<WishlistListController>(
      create: (ctx) => WishlistListController(repository: ctx.read())..loadMyWishlist()
    )
  ];
}