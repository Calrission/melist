import 'package:flutter/widgets.dart';
import 'package:melist/domain/interfaces/i_telegram_repository.dart';
import 'package:melist/presentation/controllers/app_bootstrap_controller.dart';
import 'package:melist/presentation/widgets/loading_widget.dart';
import 'package:melist/presentation/widgets/not_telegram_error_widget.dart';
import 'package:provider/provider.dart';

/// Holds the nested navigator until session restore finishes.
class SessionGate extends StatelessWidget {
  const SessionGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<AppBootstrapController>().ready;
    if (!ready) {
      return const LoadingWidget();
    }
    if (!context.read<ITelegramRepository>().isAvailable) {
      return const NotTelegramErrorWidget();
    }
    return child;
  }
}
