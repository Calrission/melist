import 'wish_item_model.dart';

class WithListModel {
  final int id;
  final int index;
  final int ownerId;
  final String name;
  final String? description;
  final bool isPublic;
  final List<WishItemModel> items;

  WithListModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.index,
    required this.description,
    required this.isPublic,
    required this.items
  });
}