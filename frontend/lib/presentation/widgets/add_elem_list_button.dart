import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/extensions/theme_extension.dart';
import 'package:melist/presentation/theme/consts.dart';

class AddElemListButton extends StatelessWidget{

  final String text;
  final VoidCallback onTap;

  const AddElemListButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.container,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        hoverColor: context.palette.subText.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: context.palette.accent),
              const SizedBox(width: smallSep),
              Text(
                text,
                style: TextStyle(color: context.palette.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}