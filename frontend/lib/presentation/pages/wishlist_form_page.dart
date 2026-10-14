import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wishlist_form_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
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
  bool isPublic = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WishlistFormController>().reset();
    if (widget.isEdit) {
      context.postFrame(() {
        scheduleMicrotask(() async {
          final model = await context.read<WishlistFormController>().loadById(
            widget.wishlistId!,
          );
          if (model == null) {
            return;
          }
          if (!mounted) {
            return;
          }
          setState(() {
            _nameController.text = model.name;
            _descriptionController.text = model.description ?? '';
            isPublic = model.visibility == WishlistVisibility.public;
          });
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
    return Scaffold(
      body: switch (controller.state) {
        ControllerState.init || ControllerState.loaded => _buildForm(context),
        ControllerState.loading => LoadingWidget(),
        ControllerState.error => ErrorPlaceholderWidget(),
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        spacing: 12,
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
            mainAxisSize: .min,
            spacing: 8,
            children: [
              Checkbox(
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value ?? !isPublic;
                  });
                },
              ),
              Text("Публичный"),
            ],
          ),
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
}
