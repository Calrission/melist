import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:melist/data/network/dio_credentials.dart';
import 'package:melist/domain/models/config.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class DioProvider {
  static Dio create(Config config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiUrl,
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      ),
    );
    applyCredentials(dio);
    return dio;
  }

  static SingleChildWidget get provider => Provider(
      create: (ctx) => create(ctx.read<Config>())
  );

  static Dio of(BuildContext context) => context.read<Dio>();
}
