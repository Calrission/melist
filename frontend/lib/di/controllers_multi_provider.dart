import 'package:melist/presentation/controllers/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ControllersMultiProvider {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<ProfileController>(create: (ctx) => ProfileController(repository: ctx.read()))
  ];
}