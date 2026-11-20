import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/domain/interfaces/i_wish_repository.dart';
import 'package:melist/presentation/controllers/reservations_controller.dart';
import 'package:melist/presentation/pages/reservations_page.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist_core/melist_core.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the description and who the wish is for', (tester) async {
    final controller = ReservationsController(repository: _Wishes());

    await tester.pumpWidget(
      ChangeNotifierProvider<ReservationsController>.value(
        value: controller,
        child: MaterialApp(
          theme: Palette.light().themeData,
          home: const ReservationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Забронированные хотелки'), findsOneWidget);
    expect(
      find.textContaining('которые вы решили им подарить'),
      findsOneWidget,
    );
    expect(find.text('Для: Света Миндаль'), findsOneWidget);
    expect(find.text('Hardcover'), findsNothing);
    expect(find.text('Добавить желание'), findsNothing);
  });

  testWidgets('a released wish disappears after returning', (tester) async {
    final wishes = _Wishes();
    final controller = ReservationsController(repository: wishes);
    final router = GoRouter(
      initialLocation: '/reservations',
      routes: [
        GoRoute(
          path: '/reservations',
          builder: (_, _) => const ReservationsPage(),
        ),
        GoRoute(
          path: '/wishes/:id',
          name: wishDetailsGoKey,
          builder: (_, _) => const Scaffold(body: Text('Детали')),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ReservationsController>.value(
        value: controller,
        child: MaterialApp.router(
          theme: Palette.light().themeData,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Для: Света Миндаль'), findsOneWidget);
    wishes.released = true;

    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();
    expect(find.text('Детали'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Для: Света Миндаль'), findsNothing);
    expect(find.text('Book'), findsNothing);
  });
}

class _Wishes implements IWishRepository {
  var released = false;

  @override
  Future<List<WishModel>> getMyReservations() async {
    if (released) {
      return const [];
    }
    return const [
      WishModel(
        id: 1,
        ownerId: 2,
        name: 'Book',
        description: 'Hardcover',
        status: WishStatus.reserved,
        reservedByMe: true,
        ownerNickname: 'Света Миндаль',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
