import 'package:go_router/go_router.dart';
import 'package:melist/presentation/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class RouterProvider {
  static SingleChildWidget get provider => Provider<GoRouter>(
    create: (_) => createAppRouter(),
    dispose: (_, router) => router.dispose(),
  );
}
