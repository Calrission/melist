extension ReorderExtension on List {
  void reorder(int oldIndex, int newIndex) {
    final int? id = removeAt(oldIndex);
    insert(newIndex, id);
  }
}