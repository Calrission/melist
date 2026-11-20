import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist/presentation/widgets/wish_booking_button.dart';

void main() {
  final palette = Palette.light();

  Widget host(Widget child) {
    return MaterialApp(
      theme: palette.themeData,
      home: Scaffold(body: child),
    );
  }

  testWidgets('a free wish offers to book it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        WishBookingButton(
          booking: WishBooking.available,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Забронировать хотелку'));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('a wish booked by me can be released', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        WishBookingButton(booking: WishBooking.mine, onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Снять бронь хотелки'));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('a wish booked by someone else uses the inactive fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const WishBookingButton(booking: WishBooking.taken)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      button.style?.backgroundColor?.resolve({WidgetState.disabled}),
      palette.inactive,
    );
    expect(palette.inactive, const Color(0xFF9F9F9F));
  });
}
