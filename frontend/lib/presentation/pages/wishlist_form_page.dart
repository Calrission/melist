import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
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
  bool isPublic = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      context.postFrame(() {
        scheduleMicrotask(() async {
          final model = await context.read<WishlistFormController>().loadById(
            widget.wishlistId!,
          );
          if (model == null) {
            return;
          }
          _nameController.text = model.name;
          _descriptionController.text = model.description ?? '';
          isPublic = model.visibility == WishlistVisibility.public;
        });
      });
    }
  }

  Future<void> save() async {
    final controller = context.read<WishlistFormController>();
    final saved = widget.isEdit
        ? await controller.update(
            widget.wishlistId!,
            PatchWishlistBody(
              name: _nameController.text,
              description: _descriptionController.text,
              visibility: WishlistVisibility.fromBool(isPublic),
            ),
          )
        : await controller.create(
            CreateWishlistBody(
              name: _nameController.text,
              description: _descriptionController.text,
              visibility: WishlistVisibility.fromBool(isPublic),
            ),
          );

    if (!mounted || !saved) {
      return;
    }
    context.pop();
    controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishlistFormController>();
    final bool isEnabled = controller.state == ControllerState.init;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Column(
          spacing: 12,
          children: [
            TextField(
              enabled: isEnabled,
              controller: _nameController,
              decoration: InputDecoration(hint: Text("Название")),
            ),

            TextField(
              enabled: isEnabled,
              controller: _descriptionController,
              decoration: InputDecoration(hint: Text("Описание")),
            ),

            Row(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                Checkbox(
                  value: isPublic,
                  onChanged: isEnabled
                      ? (value) {
                          setState(() {
                            isPublic = value ?? !isPublic;
                          });
                        }
                      : null,
                ),
                Text("Публичный"),
              ],
            ),

            Row(
              mainAxisAlignment: .end,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: isEnabled
                      ? () {
                          context.pop();
                        }
                      : null,
                  child: Text("Отмена"),
                ),
                FilledButton(onPressed: save, child: Text("Сохранить")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
