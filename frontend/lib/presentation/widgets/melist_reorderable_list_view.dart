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
    return CustomScrollView(
      clipBehavior: Clip.hardEdge,
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: MelistReorderableSliver(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            onReorderItem: onReorderItem,
            reorderEnabled: reorderEnabled,
          ),
        ),
      ],
    );
  }
}

/// Reorderable sliver used inside a [CustomScrollView] that also has headers.
class MelistReorderableSliver extends StatelessWidget {
  const MelistReorderableSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorderItem,
    this.reorderEnabled = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorderItem;
  final bool reorderEnabled;

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
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
