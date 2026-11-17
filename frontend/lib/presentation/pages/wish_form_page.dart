import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/wish_form_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/error_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/labeled_bottom_sheet_selector.dart';
import 'package:melist/presentation/widgets/labeled_multi_select_bottom_sheet_selector.dart';
import 'package:melist/presentation/widgets/labeled_text_field.dart';
import 'package:melist/presentation/widgets/price_input_formatter.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
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
  final FocusNode _priceFocusNode = FocusNode();
  WishStatus _status = WishStatus.free;
  bool _loadFailed = false;
  bool _saving = false;
  final Set<int> _selectedWishlistIds = {};

  @override
  void initState() {
    super.initState();
    _priceFocusNode.addListener(_updatePriceSuffix);
    context.read<WishFormController>().reset(silence: true);
    if (widget.fromWishlistId != null) {
      _selectedWishlistIds.add(widget.fromWishlistId!);
    }
    context.postFrame(() {
      scheduleMicrotask(() async {
        final wishlistList = context.read<WishlistListController>();
        final wishForm = context.read<WishFormController>();
        if (wishlistList.state != ControllerState.loaded) {
          await wishlistList.loadMyWishlist();
        }
        if (!mounted) {
          return;
        }
        if (widget.isEdit) {
          final model = await wishForm.loadById(widget.wishId!);
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
            _updatePriceSuffix();
            _linkController.text = model.url ?? '';
            _coverUrlController.text = model.coverUrl ?? '';
            _status = model.status;
            _selectedWishlistIds
              ..clear()
              ..addAll(
                (wishlistList.data ?? const <WishlistModel>[])
                    .where(
                      (wishlist) => wishlist.items.any(
                        (wish) => wish.id == widget.wishId,
                      ),
                    )
                    .map((wishlist) => wishlist.id),
              );
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _coverUrlController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _priceFocusNode
      ..removeListener(_updatePriceSuffix)
      ..dispose();
    super.dispose();
  }

  void _updatePriceSuffix() {
    final text = _priceController.text;
    final numericText = text.replaceFirst(RegExp(r'\s*₽$'), '').trimRight();
    final nextText = _priceFocusNode.hasFocus || numericText.isEmpty
        ? numericText
        : '$numericText ₽';
    if (nextText == text) {
      return;
    }
    _priceController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  String? _textOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _statusLabel(WishStatus status) => switch (status) {
    WishStatus.draft => "Черновик",
    WishStatus.free => "Свободно",
    WishStatus.reserved => "Зарезервировано",
  };

  void _onWishlistSelectionChanged(Set<int> ids) {
    setState(() {
      _selectedWishlistIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _editCoverUrl() async {
    if (_coverUrlController.text.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Редактирование обложки"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Заменить обложку"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Удалить обложку"),
            ),
          ],
        ),
      );
      if (!mounted || replace == null) {
        return;
      }
      if (!replace) {
        setState(_coverUrlController.clear);
        return;
      }
    }

    await _showCoverUrlDialog();
  }

  Future<void> _showCoverUrlDialog() async {
    final controller = TextEditingController(text: _coverUrlController.text);
    try {
      final url = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: "Ссылка на обложку",
                suffixIcon: IconButton(
                  tooltip: "Вставить из буфера обмена",
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text;
                    if (text == null) {
                      return;
                    }
                    controller.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                    setDialogState(() {});
                  },
                ),
              ),
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Отмена"),
              ),
              TextButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () =>
                          Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text("Ок"),
              ),
            ],
          ),
        ),
      );
      if (url != null && mounted) {
        setState(() {
          _coverUrlController.text = url;
        });
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> save() async {
    setState(() => _saving = true);
    final controller = context.read<WishFormController>();
    final price = double.tryParse(
      _priceController.text.replaceAll('₽', '').trim(),
    );
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
        _selectedWishlistIds,
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
        _selectedWishlistIds,
      );
    }

    if (!mounted) return;
    if (isSuccess) {
      context.pop();
      controller.reset();
    } else {
      setState(() => _saving = false);
      context.showError(controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WishFormController>();
    return Scaffold(
      appBar: MelistAppBar(
        title: widget.isEdit ? "Редактирование желания" : "Новое желание",
      ),
      body: _loadFailed
          ? ErrorPlaceholderWidget(error: controller.error)
          : _saving || controller.state == ControllerState.loading
          ? LoadingWidget()
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final wishlistList = context.watch<WishlistListController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Material(
                        color: context.palette.accent,
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: InkWell(
                          onTap: _editCoverUrl,
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: _coverUrlController.text.isEmpty
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 400,
                                    child: Center(
                                      child: Text(
                                        "Добавить обложку хотелки",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: context.palette.textOnAccent,
                                        ),
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _coverUrlController.text,
                                    height: 400,
                                    fit: BoxFit.fitHeight,
                                    placeholder: (context, url) => SizedBox(
                                      height: 400,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: context.palette.textOnAccent,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        SizedBox(
                                          height: 400,
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color:
                                                  context.palette.textOnAccent,
                                            ),
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  LabeledTextField(
                    label: "Название",
                    hint: "Введите название",
                    controller: _nameController,
                    inputFormatters: const [
                      LengthLimitingTextInputFormatter(255),
                    ],
                  ),
                  LabeledTextField(
                    label: "Описание",
                    hint: "Введите описание",
                    controller: _descriptionController,
                    maxLines: null,
                  ),
                  LabeledBottomSheetSelector<WishStatus>(
                    label: "Статус",
                    value: _status,
                    options: WishStatus.values,
                    optionLabel: _statusLabel,
                    onChanged: (status) => setState(() => _status = status),
                  ),
                  LabeledTextField(
                    label: "Цена",
                    hint: "Цена в рублях",
                    controller: _priceController,
                    focusNode: _priceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [PriceInputFormatter()],
                  ),
                  LabeledTextField(
                    label: "Ссылка",
                    hint: "Введите ссылку",
                    controller: _linkController,
                  ),
                  if (wishlistList.data != null)
                    LabeledMultiSelectBottomSheetSelector(
                      label: "Вишлисты",
                      options: wishlistList.data!,
                      selectedIds: _selectedWishlistIds,
                      onChanged: _onWishlistSelectionChanged,
                    )
                  else if (wishlistList.state == ControllerState.error)
                    ErrorPlaceholderWidget(
                      error: wishlistList.error,
                      onRetry: wishlistList.loadMyWishlist,
                    )
                  else
                    const LoadingWidget(),
                  SizedBox(height: 18),
                ],
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              minimumSize: null,
              maximumSize: null,
              backgroundColor: context.palette.accent,
              foregroundColor: context.palette.textOnAccent,
            ),
            onPressed: wishlistList.data == null ? null : save,
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }
}
