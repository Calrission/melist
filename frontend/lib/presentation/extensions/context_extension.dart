import 'package:flutter/widgets.dart';
import 'package:melist/presentation/theme/consts.dart';

extension ContextExtension on BuildContext {
  /// Page inset for a scroll view's children.
  ///
  /// Pass this to the scroll view's own `padding`. A [Padding] around the
  /// scroll view would pull the scrollbar in with the items.
  EdgeInsets listContentPadding({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final safe = MediaQuery.paddingOf(this);
    return EdgeInsets.fromLTRB(
      horPagePadding + left,
      safe.top + top,
      horPagePadding + right,
      safe.bottom + bottom,
    );
  }

  void postFrame(void Function() callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback();
    });
  }
}
