class WishItemModel {
  final int id;
  final int ownerId;
  final int index;
  final String name;
  final String photoUrl;
  final String url;
  final double price;
  final String? comment;

  WishItemModel({
    required this.id,
    required this.ownerId,
    required this.index,
    required this.name,
    required this.photoUrl,
    required this.url,
    required this.price,
    required this.comment
  });
}