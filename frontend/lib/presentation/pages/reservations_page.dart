import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/reservations_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:provider/provider.dart';

const _description =
    'Здесь можно посмотреть забронированные вами хотелки. '
    'Это хотелки других пользователей, которые вы решили им подарить';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      context.read<ReservationsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReservationsController>();
    return Scaffold(
      appBar: const MelistAppBar(title: 'Забронированные хотелки'),
      body: controller.state == ControllerState.error
          ? ErrorPlaceholderWidget(
              error: controller.error,
              onRetry: controller.load,
            )
          : controller.state == ControllerState.loaded
          ? const _LoadedReservations()
          : const LoadingWidget(),
    );
  }
}

class _LoadedReservations extends StatelessWidget {
  const _LoadedReservations();

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ReservationsController>().data ?? const [];
    final padding = context.listContentPadding();
    return CustomScrollView(
      clipBehavior: Clip.hardEdge,
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 0),
          sliver: const SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    _description,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                  ),
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyPlaceholderWidget(),
          )
        else
          SliverPadding(
            padding: padding.copyWith(top: 0),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final wish = items[index];
                final owner = wish.ownerNickname?.trim();
                return WishTile(
                  wishModel: wish,
                  borderWhenReservedByMe: false,
                  subtitle: owner == null || owner.isEmpty
                      ? 'Для:'
                      : 'Для: $owner',
                  onTap: () async {
                    await context.pushNamed(
                      wishDetailsGoKey,
                      pathParameters: {'id': wish.id.toString()},
                      extra: WishDetailsArguments(wish: wish),
                    );
                    if (context.mounted) {
                      await context.read<ReservationsController>().refresh();
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
