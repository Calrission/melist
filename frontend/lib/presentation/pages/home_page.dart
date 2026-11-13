import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/deep_link_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/extensions/widget_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/profile_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.postFrame((){
      context.read<ProfileController>().loadProfile();
      final token = context.read<DeepLinkController>().consumeSharedToken();
      if (token != null) {
        _openShared(token);
      }
    });
  }

  void _openShared(String token) {
    context.pushNamed(sharedWishlistGoKey, pathParameters: {'token': token});
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.profile;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(horPagePadding),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            switch (profileController.state) {
              ControllerState.init => LoadingWidget(),
              ControllerState.loading => LoadingWidget(),
              ControllerState.loaded => ProfileWidget(userModel: user!),
              ControllerState.error => ErrorPlaceholderWidget(
                error: profileController.error,
                onRetry: profileController.loadProfile,
              ),
            },

            SizedBox(height: singleSep),
            Text("Хотелки и вишлисты", style: TextStyle(
              fontSize: 12,
              color: context.palette.accent,
              fontWeight: FontWeight.w600
            )),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () => context.goNamed(wishlistsGoKey),
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("Мои вишлисты").row(),
            ),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () => context.goNamed(wishesGoKey),
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("Все мои хотелки").row(),
            ),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () => context.goNamed(wishlistFavoritesGoKey),
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("Избранные вишлисты").row(),
            ),

            SizedBox(height: singleSep),
            Text("Прочее", style: TextStyle(
              fontSize: 12,
              color: context.palette.accent,
              fontWeight: FontWeight.w600
            )),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("Настройки").row(),
            ),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () => context.goNamed(subscriptionsGoKey),
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("Мои подписки").row(),
            ),
            SizedBox(height: smallSep),
            FilledButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.end,
              icon: Icon(MelistIcons.arrowRight),
              label: Text("О боте").row(),
            ),
          ],
        ),
      ),
    );
  }
}
