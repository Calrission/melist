import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/pages/wish_details_page.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist/presentation/widgets/add_elem_list_button.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:provider/provider.dart';

class WishesPage extends StatefulWidget {
  const WishesPage({super.key});

  @override
  State<WishesPage> createState() => _WishesPageState();
}

class _WishesPageState extends State<WishesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.postFrame(() {
      final controller = context.read<WishesController>();
      _searchController.text = controller.query;
      controller.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteSelected(WishesController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          "Вы уверены, что хотите удалить выбранные желания?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Да"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await context.guard(controller.deleteSelected, success: "Удалено");
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishesController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: controller.selectionMode
            ? "Удаление желаний"
            : "Все мои хотелки",
        onBack: controller.selectionMode
            ? controller.toggleSelectionMode
            : context.pop,
        actions: [
          IconButton(
            icon: Icon(
              MelistIcons.trash,
              color: controller.selectedIds.isNotEmpty
                  ? context.palette.accent
                  : controller.selectionMode
                  ? context.palette.subText
                  : context.palette.text,
            ),
            onPressed:
                controller.selectionMode && controller.selectedIds.isNotEmpty
                ? () => _confirmDeleteSelected(controller)
                : controller.toggleSelectionMode,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!controller.selectionMode) ...[
            const SizedBox(height: smallSep),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horPagePadding),
              child: AddElemListButton(
                text: "Создать новую хотелку",
                onTap: () => context.goNamed(wishNewGoKey),
              ),
            ),
            const SizedBox(height: bigSep),
          ],
          Expanded(
            child: switch (controller.state) {
              ControllerState.init ||
              ControllerState.loading => LoadingWidget(),
              ControllerState.error => ErrorPlaceholderWidget(
                error: controller.error,
                onRetry: controller.load,
              ),
              ControllerState.loaded => const _WishesList(),
            },
          ),
        ],
      ),
    );
  }
}

class _WishesList extends StatelessWidget {
  const _WishesList();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishesController>();
    final wishes = controller.data!;
    if (wishes.isEmpty) {
      return EmptyPlaceholderWidget();
    }
    final selectionMode = controller.selectionMode;
    return ListView.builder(
      padding: context.listContentPadding(),
      itemCount: wishes.length,
      itemBuilder: (context, index) {
        final e = wishes[index];
        return WishTile(
          key: ValueKey(e.id),
          wishModel: e,
          selected: selectionMode
              ? controller.selectedIds.contains(e.id)
              : null,
          onSelect: (_) => controller.toggleSelect(e.id),
          onTap: selectionMode
              ? () => controller.toggleSelect(e.id)
              : () => context.goNamed(
                  wishDetailsGoKey,
                  pathParameters: {'id': e.id.toString()},
                  extra: WishDetailsArguments(wish: e),
                ),
          actions: [
            if (!selectionMode)
              IconButton(
                tooltip: "Дублировать",
                onPressed: () => context.guard(
                  () => controller.duplicate(e.id),
                  success: "Копия создана",
                ),
                icon: Icon(Icons.copy),
              ),
          ],
        );
      },
    );
  }
}
