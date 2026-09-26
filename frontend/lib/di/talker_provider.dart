import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class TalkerProvider {
  static Talker create([Dio? dio]) {
    final talker = Talker();
    dio?.interceptors.add(TalkerDioLogger(
      talker: talker,
      settings: const TalkerDioLoggerSettings(
        printResponseMessage: true,
      ),
    ));
    return talker;
  }

  static SingleChildWidget get provider => Provider(
    lazy: false,
    create: (ctx) => create(ctx.read<Dio>()),
  );
}