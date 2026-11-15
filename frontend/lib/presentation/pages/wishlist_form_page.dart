import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/labeled_bottom_sheet_selector.dart';
import 'package:melist/presentation/widgets/labeled_text_field.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishlistFormPage extends StatefulWidget {
  final int? wishlistId;
  bool get isEdit => wishlistId != null;

  const WishlistFormPage({super.key, this.wishlistId});

  @override
  State<WishlistFormPage> createState() => _WishlistFormPageState();
}

class _WishlistFormPageState extends State<WishlistFormPage> {
  WishlistVisibility visibility = WishlistVisibility.draft;
  final Set<int> wishIds = {};
  bool loadFailed = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WishlistFormController>().reset(silence: true);
    if (widget.isEdit) {
      context.postFrame(() {
        scheduleMicrotask(() async {
          final model = await context.read<WishlistFormController>().loadById(
            widget.wishlistId!,
          );
          if (!mounted) {
            return;
          }
          if (model == null) {
            setState(() => loadFailed = true);
            return;
          }
          setState(() {
            _nameController.text = model.name;
            _descriptionController.text = model.description ?? '';
            visibility = model.visibility;
          });
        });
      });
    } else {
      context.postFrame(() => context.read<WishesController>().load(query: ''));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final controller = context.read<WishlistFormController>();
    final description = _descriptionController.text.trim();
    final saved = widget.isEdit
        ? await controller.update(
            widget.wishlistId!,
            PatchWishlistBody(
              name: _nameController.text,
              description: description.isEmpty ? null : description,
              visibility: visibility,
            ),
          )
        : await controller.create(
            CreateWishlistBody(
              name: _nameController.text,
              description: description.isEmpty ? null : description,
              visibility: visibility,
              wishIds: wishIds.toList(),
            ),
          );

    if (!mounted) {
      return;
    }
    if (!saved) {
      context.showError(controller.error!);
      return;
    }
    context.pop();
    controller.reset();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text("Вы уверены, что хотите удалить этот вишлист?"),
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

    final controller = context.read<WishlistFormController>();
    final deleted = await controller.delete(widget.wishlistId!);
    if (!mounted) {
      return;
    }
    if (!deleted) {
      context.showError(controller.error!);
      return;
    }
    context.pop();
    controller.reset();
  }

  String _visibilityLabel(WishlistVisibility value) => switch (value) {
    WishlistVisibility.public => "Публичный",
    WishlistVisibility.draft => "Черновик",
    WishlistVisibility.link => "По ссылке",
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistFormController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: widget.isEdit ? "Редактирование вишлиста" : "Новый вишлист",
        actions: widget.isEdit
            ? [
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(MelistIcons.trash),
                ),
              ]
            : null,
      ),
      body: loadFailed
          ? ErrorPlaceholderWidget(error: controller.error)
          : controller.state == ControllerState.loading
          ? LoadingWidget()
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 12,
                crossAxisAlignment: .start,
                children: [
                  LabeledTextField(
                    label: "Название",
                    hint: "Новый год",
                    controller: _nameController,
                  ),
                  LabeledTextField(
                    label: "Описание",
                    hint: "Введите описание",
                    controller: _descriptionController,
                    maxLines: null,
                  ),
                  LabeledBottomSheetSelector<WishlistVisibility>(
                    label: "Видимость",
                    value: visibility,
                    options: WishlistVisibility.values,
                    optionLabel: _visibilityLabel,
                    onChanged: (value) => setState(() => visibility = value),
                  ),
                  SizedBox(height: 18),
                ],
              ),
            ),
          ),
          FilledButton(onPressed: save, child: Text("Сохранить")),
        ],
      ),
    );
  }
}
