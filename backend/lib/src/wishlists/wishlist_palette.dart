/// Allowed cover colors for a wishlist (1.4). Stored uppercase `#RRGGBB`.
const wishlistPalette = <String>{
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
};

const defaultWishlistColor = '#FFB74D';

String? normalizeWishlistColor(String raw) {
  final color = raw.trim().toUpperCase();
  if (!wishlistPalette.contains(color)) {
    return null;
  }
  return color;
}
