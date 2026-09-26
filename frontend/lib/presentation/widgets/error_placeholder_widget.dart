import 'package:flutter/material.dart';

class ErrorPlaceholderWidget extends StatelessWidget {
  const ErrorPlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          Icon(Icons.error_outline),
          Text("Что-то пошло не так :(")
        ],
      ),
    );
  }
}
