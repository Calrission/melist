import 'package:material_ui/material_ui.dart';

class MelistReorderableListView extends StatelessWidget {
  const MelistReorderableListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorderItem,
    this.padding,
    this.reorderEnabled = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorderItem;
  final EdgeInsets? padding;

  /// While false, a long press does not start a reorder.
  final bool reorderEnabled;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: padding,
      clipBehavior: Clip.hardEdge,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => child,
      onReorderItem: onReorderItem,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final child = itemBuilder(context, index);
        return ReorderableDelayedDragStartListener(
          key: child.key,
          index: index,
          enabled: reorderEnabled,
          child: child,
        );
      },
    );
  }
}
