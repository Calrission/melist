import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishes_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/theme/wishlist_palette.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
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
  String color = defaultWishlistColor;
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
            color = model.color;
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
              color: color,
            ),
          )
        : await controller.create(
            CreateWishlistBody(
              name: _nameController.text,
              description: description.isEmpty ? null : description,
              visibility: visibility,
              color: color,
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistFormController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Редактирование вишлиста" : "Новый вишлист"),
      ),
      body: loadFailed
          ? ErrorPlaceholderWidget(error: controller.error)
          : controller.state == ControllerState.loading
              ? LoadingWidget()
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        spacing: 12,
        crossAxisAlignment: .start,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hint: Text("Название")),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(hint: Text("Описание")),
          ),
          Row(
            spacing: 8,
            children: [
              Text("Видимость:"),
              DropdownButton<WishlistVisibility>(
                value: visibility,
                items: [
                  for (final value in WishlistVisibility.values)
                    DropdownMenuItem(value: value, child: Text(value.name)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => visibility = value);
                  }
                },
              ),
            ],
          ),
          Text("Цвет: $color"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in wishlistPalette)
                InkWell(
                  onTap: () => setState(() => color = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      border: Border.all(
                        width: hex == color ? 3 : 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (!widget.isEdit) _buildWishPicker(),
          Row(
            mainAxisAlignment: .end,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: context.pop,
                child: Text("Отмена"),
              ),
              FilledButton(onPressed: save, child: Text("Сохранить")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWishPicker() {
    return Consumer<WishesController>(
      builder: (context, wishes, _) {
        if (wishes.state != ControllerState.loaded) {
          return Text("Загрузка желаний...");
        }
        final items = wishes.data!;
        return Column(
          crossAxisAlignment: .start,
          children: [
            Text("Добавить существующие желания:"),
            if (items.isEmpty) Text("Желаний пока нет"),
            for (final wish in items)
              CheckboxListTile(
                value: wishIds.contains(wish.id),
                title: Text(wish.name),
                onChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      wishIds.add(wish.id);
                    } else {
                      wishIds.remove(wish.id);
                    }
                  });
                },
              ),
          ],
        );
      },
    );
  }
}
