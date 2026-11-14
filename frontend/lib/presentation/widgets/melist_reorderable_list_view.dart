import 'package:material_ui/material_ui.dart';

class MelistReorderableListView extends StatelessWidget {
  const MelistReorderableListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorderItem,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorderItem;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: padding,
      clipBehavior: Clip.hardEdge,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => child,
      onReorderItem: onReorderItem,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
