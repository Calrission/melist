import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/context_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist/presentation/theme/palette.dart';

void main() {
  testWidgets(
    'list items stay at the page inset while the scrollbar sits 2px from the edge',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final theme = Palette.light().themeData.copyWith(
        platform: TargetPlatform.windows,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ListView.builder(
                  padding: context.listContentPadding(),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    return SizedBox(height: 48, child: Text('item $index'));
                  },
                );
              },
            ),
          ),
        ),
      );

      final width = tester.getSize(find.byType(Scaffold)).width;
      final item = tester.getRect(find.text('item 0'));
      final scrollable = tester.getRect(find.byType(Scrollable));

      expect(item.left, horPagePadding);
      expect(width - item.right, horPagePadding);
      expect(scrollable.left, 0);
      expect(scrollable.right, width);

      final scrollbar = tester.state<RawScrollbarState>(
        find.byWidgetPredicate((widget) => widget is RawScrollbar),
      );
      // ignore: invalid_use_of_protected_member
      expect(scrollbar.scrollbarPainter.crossAxisMargin, scrollbarInset);
    },
  );
}
