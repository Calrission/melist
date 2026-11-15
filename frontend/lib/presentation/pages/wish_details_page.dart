import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/widgets/error_placeholder_widget.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/melist_app_bar.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

class WishDetailsArguments {
  const WishDetailsArguments({required this.wish});

  final WishModel wish;
}

class WishDetailsPage extends StatefulWidget {
  const WishDetailsPage({super.key, required this.wishId, this.initialWish});

  final int wishId;
  final WishModel? initialWish;

  @override
  State<WishDetailsPage> createState() => _WishDetailsPageState();
}

class _WishDetailsPageState extends State<WishDetailsPage> {
  WishModel? _wish;
  Object? _error;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _wish = widget.initialWish;
    if (_wish == null) {
      _loading = true;
      context.postFrame(_load);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wish = await context.read<IWishRepository>().getMyWishById(
        widget.wishId,
      );
      if (!mounted) return;
      setState(() {
        _wish = wish;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _statusLabel(WishStatus status) => switch (status) {
    WishStatus.draft => "Черновик",
    WishStatus.free => "Свободно",
    WishStatus.reserved => "Зарезервировано",
  };

  @override
  Widget build(BuildContext context) {
    final wish = _wish;
    return Scaffold(
      appBar: MelistAppBar(title: wish?.name ?? "Желание"),
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
          if (wish.description?.isNotEmpty ?? false)
            Text(wish.description!, style: TextStyle(
                fontWeight: FontWeight.w300,
                color: context.palette.text,
                fontSize: 12
            )),
          _WishDetailField(label: "Статус", value: _statusLabel(wish.status)),
          _WishDetailField(
            label: "Цена",
            value: wish.price == null ? "—" : "${wish.price} ₽",
          ),
          _WishDetailField(label: "Ссылка", value: wish.url ?? "—"),
        ],
      ),
    );
  }
}

class _WishDetailField extends StatelessWidget {
  const _WishDetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: context.palette.accent,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.palette.container,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: context.palette.text),
          ),
        ),
      ],
    );
  }
}
