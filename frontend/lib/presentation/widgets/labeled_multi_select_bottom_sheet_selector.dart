import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';
import 'package:melist_core/melist_core.dart';

class LabeledMultiSelectBottomSheetSelector extends StatelessWidget {
  const LabeledMultiSelectBottomSheetSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  final String label;
  final List<WishlistModel> options;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.background,
      isScrollControlled: true,
      builder: (sheetContext) {
        final draftSelection = {...selectedIds};
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: sheetContext.palette.containerAccent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (options.isEmpty)
                          const ListTile(title: Text("Нет вишлистов")),
                        for (final wishlist in options)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(borderRadius),
                              child: Material(
                                color: draftSelection.contains(wishlist.id)
                                    ? sheetContext.palette.containerAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  title: Text(wishlist.name),
                                  onTap: () {
                                    setSheetState(() {
                                      if (!draftSelection.remove(wishlist.id)) {
                                        draftSelection.add(wishlist.id);
                                      }
                                    });
                                    onChanged(Set<int>.of(draftSelection));
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedIds.length;
    final selectedLabel = switch (selectedCount % 100) {
      >= 11 && <= 14 => "вишлистов",
      _ => switch (selectedCount % 10) {
        1 => "вишлист",
        >= 2 && <= 4 => "вишлиста",
        _ => "вишлистов",
      },
    };
    final selectionText = switch (selectedCount) {
      0 => "Выберите вишлисты",
      1 =>
        options
                .where((wishlist) => selectedIds.contains(wishlist.id))
                .map((wishlist) => wishlist.name)
                .firstOrNull ??
            "Выбрано 1 вишлист",
      _ => "Выбрано $selectedCount $selectedLabel",
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: context.palette.accent,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: context.palette.container,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: () => _showOptions(context),
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectionText,
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedCount == 0
                            ? context.palette.subText
                            : context.palette.text,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.palette.subText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
