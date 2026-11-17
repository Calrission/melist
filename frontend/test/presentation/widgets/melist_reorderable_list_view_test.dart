import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/widgets/melist_reorderable_list_view.dart';

void main() {
  testWidgets('a drag scrolls the list without moving cards', (tester) async {
    final items = List<int>.generate(20, (index) => index);
    await tester.pumpWidget(_host(items));

    await tester.drag(find.text('item 0'), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(items, List<int>.generate(20, (index) => index));
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });

  testWidgets('a long press then drag reorders a card', (tester) async {
    final items = List<int>.generate(20, (index) => index);
    await tester.pumpWidget(_host(items));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('item 0')),
    );
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(items.first, isNot(0));
    expect(items, contains(0));
  });

  testWidgets('long press does not reorder when reordering is disabled', (
    tester,
  ) async {
    final items = List<int>.generate(20, (index) => index);
    await tester.pumpWidget(_host(items, reorderEnabled: false));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('item 0')),
    );
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(items, List<int>.generate(20, (index) => index));
  });
}

Widget _host(List<int> items, {bool reorderEnabled = true}) {
  return MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) {
          return MelistReorderableListView(
            reorderEnabled: reorderEnabled,
            itemCount: items.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return SizedBox(
                key: ValueKey(items[index]),
                height: 80,
                child: Text('item ${items[index]}'),
              );
            },
          );
        },
      ),
    ),
  );
}
