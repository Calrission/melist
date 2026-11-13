import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/error_extension.dart';

class ErrorPlaceholderWidget extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const ErrorPlaceholderWidget({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          Icon(Icons.error_outline),
          Text("Что-то пошло не так :("),
          if (error != null) Text(errorMessage(error!)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text("Повторить")),
        ],
      ),
    );
  }
}
