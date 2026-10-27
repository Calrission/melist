import 'package:flutter/painting.dart';

/// Must match `backend/lib/src/wishlists/wishlist_palette.dart`.
const wishlistPalette = <String>[
  '#FFB74D',
  '#EF5350',
  '#EC407A',
  '#AB47BC',
  '#7E57C2',
  '#5C6BC0',
  '#42A5F5',
  '#26A69A',
  '#66BB6A',
  '#D4E157',
  '#8D6E63',
  '#78909C',
];

const defaultWishlistColor = '#FFB74D';

Color colorFromHex(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0;
  return Color(0xFF000000 | value);
}
