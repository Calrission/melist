import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/base_controller.dart';
import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:melist/presentation/controllers/wishlist_list_controller.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/icons/melist_icons.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/labeled_text_field.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishDetailsArguments {
  const WishDetailsArguments({required this.wish, this.sourceWishlistName});

  final WishModel wish;
  final String? sourceWishlistName;
}

class WishDetailsPage extends StatefulWidget {
  const WishDetailsPage({
    super.key,
    required this.wishId,
    this.initialWish,
    this.sourceWishlistName,
  });

  final int wishId;
  final WishModel? initialWish;
  final String? sourceWishlistName;

  @override
  State<WishDetailsPage> createState() => _WishDetailsPageState();
}

class _WishDetailsPageState extends State<WishDetailsPage> {
  WishModel? _wish;
  Object? _error;
  var _loading = true;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  final _statusController = TextEditingController();
  final _wishlistsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _wish = widget.initialWish;
    context.postFrame(() => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _statusController.dispose();
    _wishlistsController.dispose();
    super.dispose();
  }

  String _statusLabel(WishStatus status) => switch (status) {
    WishStatus.draft => "Черновик",
    WishStatus.free => "Свободно",
    WishStatus.reserved => "Зарезервировано",
  };

  void _applyWish(WishModel wish) {
    _wish = wish;
    _nameController.text = wish.name;
    _descriptionController.text = wish.description ?? '';
    _priceController.text = wish.price == null ? '' : '${wish.price} ₽';
    _urlController.text = wish.url ?? '';
    _statusController.text = _statusLabel(wish.status);
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profileController = context.read<ProfileController>();
      final wishRepository = context.read<IWishRepository>();
      final wishlistsController = context.read<WishlistListController>();
      if (profileController.profile == null) {
        await profileController.loadProfile();
      }

      final profileId = profileController.profile?.id;
      final currentWish = _wish;
      final isOwn = currentWish != null && currentWish.ownerId == profileId;
      final wish = currentWish == null || (refresh && isOwn)
          ? await wishRepository.getMyWishById(widget.wishId)
          : currentWish;

      if (!mounted) return;
      setState(() {
        _applyWish(wish);
        _loading = false;
      });

      if (wish.ownerId == profileId) {
        if (wishlistsController.state != ControllerState.loaded) {
          await wishlistsController.loadMyWishlist();
        }
        if (mounted) _updateWishlistsField(wishlistsController.data);
      } else {
        _updateWishlistsField(null);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  void _updateWishlistsField(List<WishlistModel>? wishlists) {
    final wish = _wish;
    if (wish == null) return;
    final names = wishlists
        ?.where((wishlist) => wishlist.items.any((item) => item.id == wish.id))
        .map((wishlist) => wishlist.name)
        .toList();
    _wishlistsController.text = names?.isNotEmpty == true
        ? names!.join(', ')
        : widget.sourceWishlistName ?? '';
  }

  Future<void> _edit() async {
    await context.pushNamed<void>(
      wishEditGoKey,
      pathParameters: {'id': widget.wishId.toString()},
    );
    if (mounted) await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final wish = _wish;
    final profileId = context.watch<ProfileController>().profile?.id;
    final isOwn = wish != null && wish.ownerId == profileId;

    return Scaffold(
      appBar: MelistAppBar(
        title: wish?.name ?? "Желание",
        actions: [
          if (isOwn)
            IconButton(
              tooltip: "Редактировать",
              onPressed: _edit,
              icon: Icon(MelistIcons.edit),
            ),
        ],
      ),
      body: _error != null
          ? ErrorPlaceholderWidget(error: _error!, onRetry: _load)
          : _loading || wish == null
          ? const LoadingWidget()
          : _buildDetails(context, wish),
    );
  }

  Widget _buildDetails(BuildContext context, WishModel wish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: wish.coverUrl == null || wish.coverUrl!.isEmpty
                    ? SizedBox(
                        width: double.infinity,
                        height: 400,
                        child: ColoredBox(
                          color: context.palette.accent,
                          child: Center(
                            child: Text(
                              "Обложка не добавлена",
                              style: TextStyle(
                                color: context.palette.textOnAccent,
                              ),
                            ),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: wish.coverUrl!,
                        height: 400,
                        fit: BoxFit.fitHeight,
                        placeholder: (context, url) => const SizedBox(
                          height: 400,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => SizedBox(
                          height: 400,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: context.palette.subText,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          LabeledTextField(
            label: "Название",
            hint: "",
            controller: _nameController,
            enabled: false,
          ),
          LabeledTextField(
            label: "Описание",
            hint: "",
            controller: _descriptionController,
            maxLines: null,
            enabled: false,
          ),
          LabeledTextField(
            label: "Статус",
            hint: "",
            controller: _statusController,
            enabled: false,
          ),
          LabeledTextField(
            label: "Цена",
            hint: "",
            controller: _priceController,
            enabled: false,
          ),
          LabeledTextField(
            label: "Ссылка",
            hint: "",
            controller: _urlController,
            enabled: false,
          ),
          LabeledTextField(
            label: "Вишлисты",
            hint: "",
            controller: _wishlistsController,
            maxLines: null,
            enabled: false,
          ),
        ],
      ),
    );
  }
}
