import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist/presentation/widgets/wish_tile.dart';
import 'package:melist_core/melist_core.dart';

void main() {
  final palette = Palette.light();

  Widget host(Widget child) {
    return MaterialApp(
      theme: palette.themeData,
      home: Scaffold(body: child),
    );
  }

  test('wishes taken by someone else stay in order at the bottom', () {
    const wishes = [
      WishModel(id: 1, ownerId: 1, name: 'Free'),
      WishModel(id: 2, ownerId: 1, name: 'Taken', status: WishStatus.reserved),
      WishModel(
        id: 3,
        ownerId: 1,
        name: 'Mine',
        status: WishStatus.reserved,
        reservedByMe: true,
      ),
      WishModel(id: 4, ownerId: 1, name: 'Also free'),
    ];

    expect(wishesWithTakenLast(wishes).map((wish) => wish.name), [
      'Free',
      'Mine',
      'Also free',
      'Taken',
    ]);
  });

  testWidgets('a wish taken by someone else is muted and locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const WishTile(
          wishModel: WishModel(
            id: 1,
            ownerId: 2,
            name: 'Book',
            description: 'Hardcover',
            price: 10,
            status: WishStatus.reserved,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(_border(tester).color, Colors.transparent);
    expect(_border(tester).width, 2);
    for (final label in ['Book', 'Hardcover', '10 ₽']) {
      expect(
        tester.widget<Text>(find.text(label)).style?.color,
        palette.inactive,
      );
    }
  });

  testWidgets('a wish reserved by me keeps the normal colors', (tester) async {
    await tester.pumpWidget(
      host(
        const WishTile(
          wishModel: WishModel(
            id: 1,
            ownerId: 2,
            name: 'Book',
            status: WishStatus.reserved,
            reservedByMe: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.byType(ColorFiltered), findsNothing);
    expect(tester.widget<Text>(find.text('Book')).style?.color, palette.accent);
    expect(_border(tester).color, palette.accent);
    expect(_border(tester).width, 2);
  });

  testWidgets('subtitle replaces the description', (tester) async {
    await tester.pumpWidget(
      host(
        const WishTile(
          wishModel: WishModel(
            id: 1,
            ownerId: 2,
            name: 'Book',
            description: 'Hardcover',
            status: WishStatus.reserved,
            reservedByMe: true,
          ),
          subtitle: 'Для: Света Миндаль',
          borderWhenReservedByMe: false,
        ),
      ),
    );

    expect(find.text('Для: Света Миндаль'), findsOneWidget);
    expect(find.text('Hardcover'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(_border(tester).width, 0);
  });
}

BorderSide _border(WidgetTester tester) {
  final decoration =
      tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;
  return decoration.border!.top;
}
