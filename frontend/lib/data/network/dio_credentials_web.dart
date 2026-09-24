import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Lets the browser store and send the HttpOnly refresh cookie.
void applyCredentials(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
}
