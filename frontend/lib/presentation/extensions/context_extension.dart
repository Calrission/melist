import 'package:flutter/widgets.dart';

extension ContextExtension on BuildContext {
  void postFrame(void Function() callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback();
    });
  }
}