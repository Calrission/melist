import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'a header above the list scrolls away and a later header stays pinned',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: 220, child: Text('description')),
                ),
                PinnedHeaderSliver(
                  child: SizedBox(height: 48, child: Text('add')),
                ),
                SliverList.builder(
                  itemCount: 40,
                  itemBuilder: (context, index) {
                    return SizedBox(height: 80, child: Text('item $index'));
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('description')).dy, 0);
      expect(tester.getTopLeft(find.text('add')).dy, 220);

      await tester.drag(find.text('item 0'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('add')).dy, 0);
      expect(find.text('description').hitTestable(), findsNothing);
    },
  );
}
