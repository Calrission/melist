import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishFormPage extends StatefulWidget {
  final int? fromWishlistId;
  final int? wishId;
  bool get isEdit => wishId != null;

  const WishFormPage({super.key, this.fromWishlistId, this.wishId});

  @override
  State<WishFormPage> createState() => _WishFormPageState();
}

class _WishFormPageState extends State<WishFormPage> {
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  WishStatus _status = WishStatus.free;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    context.read<WishFormController>().reset(silence: true);
    if (widget.isEdit) {
      context.postFrame(() {
        scheduleMicrotask(() async {
          final model = await context.read<WishFormController>().loadById(
            widget.wishId!,
          );
          if (!mounted) {
            return;
          }
          if (model == null) {
            setState(() => _loadFailed = true);
            return;
          }
          setState(() {
            _nameController.text = model.name;
            _descriptionController.text = model.description ?? '';
            _priceController.text = model.price?.toString() ?? '';
            _linkController.text = model.url ?? '';
            _coverUrlController.text = model.coverUrl ?? '';
            _status = model.status;
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _coverUrlController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String? _textOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> save() async {
    final controller = context.read<WishFormController>();
    final price = double.tryParse(_priceController.text.trim());
    final bool isSuccess;
    if (widget.isEdit) {
      isSuccess = await controller.update(
        widget.wishId!,
        PatchWishBody(
          name: _nameController.text,
          description: _textOrNull(_descriptionController),
          price: price,
          url: _textOrNull(_linkController),
          coverUrl: _textOrNull(_coverUrlController),
          status: _status,
        ),
      );
    } else {
      isSuccess = await controller.create(
        CreateWishBody(
          name: _nameController.text,
          description: _textOrNull(_descriptionController),
          price: price,
          url: _textOrNull(_linkController),
          coverUrl: _textOrNull(_coverUrlController),
          status: _status,
        ),
        widget.fromWishlistId,
      );
    }

    if (!mounted) return;
    if (isSuccess) {
      context.pop();
      controller.reset();
    } else {
      context.showError(controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishFormController>();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(widget.isEdit ? "Редактирование желания" : "Новое желание"),
      ),
      body: _loadFailed
          ? ErrorPlaceholderWidget(error: controller.error)
          : controller.state == ControllerState.loading
              ? LoadingWidget()
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
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
                    Row(
                      spacing: 8,
                      children: [
                        Text("Статус:"),
                        DropdownButton<WishStatus>(
                          value: _status,
                          items: [
                            for (final status in WishStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              ),
                          ],
                          onChanged: (status) {
                            if (status != null) {
                              setState(() => _status = status);
                            }
                          },
                        ),
                      ],
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
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 60),
                  ),
                  onPressed: save,
                  child: Text("Сохранить"),
                ),
              ],
            ),
          ],
        ),
      );
  }
}
