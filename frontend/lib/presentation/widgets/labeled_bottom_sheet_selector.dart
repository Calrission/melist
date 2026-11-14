import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';

class LabeledBottomSheetSelector<T> extends StatelessWidget {
  const LabeledBottomSheetSelector({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T option) optionLabel;
  final ValueChanged<T> onChanged;

  Future<void> _showOptions(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.palette.background,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: sheetContext.palette.lightAccent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 15),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Material(
                    color: value == option
                        ? sheetContext.palette.lightAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      title: Text(optionLabel(option)),
                      onTap: () => Navigator.pop(sheetContext, option),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      optionLabel(value),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.text,
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
