import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/themes.dart';

enum WishBooking { available, mine, taken }

/// Booking action on someone else's wish.
class WishBookingButton extends StatelessWidget {
  const WishBookingButton({super.key, required this.booking, this.onPressed});

  final WishBooking booking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return switch (booking) {
      WishBooking.mine => OutlinedButton(
        style: getOutlinedActionButtonStyle(palette),
        onPressed: onPressed,
        child: const Text('Снять бронь хотелки'),
      ),
      WishBooking.taken => FilledButton(
        style: getInactiveFilledButtonStyle(palette),
        onPressed: null,
        child: const Text('Забронировать хотелку'),
      ),
      WishBooking.available => FilledButton(
        onPressed: onPressed,
        child: const Text('Забронировать хотелку'),
      ),
    };
  }
}
