import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/talker/open_talker_log.dart';

class NotTelegramErrorWidget extends StatelessWidget {
  const NotTelegramErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => openTalkerLog(context),
        child: const Center(
          child: Column(
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            children: [Text("This is not a Telegram Mini App")],
          ),
        ),
      ),
    );
  }
}
