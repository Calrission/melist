import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/widgets/empty_placeholder_widget.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<WishesController>().load(query: value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishesController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: Text("Мои желания"),
        actions: [
          if (controller.selectionMode)
            TextButton(
              onPressed: controller.selectedIds.isEmpty
                  ? null
                  : () => context.guard(
                      controller.deleteSelected,
                      success: "Удалено",
                    ),
              child: Text("Удалить выбранные (${controller.selectedIds.length})"),
            ),
          TextButton(
            onPressed: controller.toggleSelectionMode,
            child: Text(controller.selectionMode ? "Отмена" : "Выбрать"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(wishNewGoKey),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(hintText: 'Поиск по названию'),
            ),
          ),
          Expanded(
            child: switch (controller.state) {
              ControllerState.init || ControllerState.loading => LoadingWidget(),
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
      itemCount: wishes.length,
      itemBuilder: (context, index) {
        final e = wishes[index];
        return WishTile(
          key: ValueKey(e.id),
          wishModel: e,
          selected: selectionMode ? controller.selectedIds.contains(e.id) : null,
          onSelect: (_) => controller.toggleSelect(e.id),
          onTap: selectionMode
              ? () => controller.toggleSelect(e.id)
              : () => context.goNamed(
                  wishEditGoKey,
                  pathParameters: {'id': e.id.toString()},
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
          onTapDelete: selectionMode
              ? null
              : () => context.guard(() => controller.delete(e.id)),
        );
      },
    );
  }
}
