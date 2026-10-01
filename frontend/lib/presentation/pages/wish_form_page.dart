import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishFormPage extends StatefulWidget {
  final int? fromWishlistId;

  const WishFormPage({super.key, this.fromWishlistId});

  @override
  State<WishFormPage> createState() => _WishFormPageState();
}

class _WishFormPageState extends State<WishFormPage> {
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  Future<void> save() async {
    final controller = context.read<WishFormController>();
    bool isSuccess = true;
    if (false) {

    } else {
      isSuccess = await controller.create(
        CreateWishBody(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          url: _linkController.text,
          coverUrl: _coverUrlController.text,
        ),
        widget.fromWishlistId,
      );
    }

    if (!mounted) return;
    if (isSuccess) {
      context.pop();
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 8,
                  children: [
                    if (_coverUrlController.text.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: _coverUrlController.text,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _coverUrlController,
                            decoration: InputDecoration(
                              hintText: 'Ссылка на обложку',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: 'Название'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(hintText: 'Описание'),
                    ),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(hintText: 'Цена в рублях'),
                    ),
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(hintText: 'Ссылка'),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: .end,
              spacing: 8,
              children: [
                OutlinedButton(onPressed: context.pop, child: Text("Отмена")),
                FilledButton(onPressed: save, child: Text("Сохранить")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
