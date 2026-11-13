import 'package:material_ui/material_ui.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        Icon(Icons.error_outline),
        Text("Ошибка")
      ],
    );
  }
}
