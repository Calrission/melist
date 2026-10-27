import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Human-readable text for an API error `{ "error": "…" }` or any exception.
String errorMessage(Object error) {
  if (error is DioException) {
    final response = error.response;
    final data = response?.data;
    if (data is Map && data['error'] is String) {
      return '${response?.statusCode}: ${data['error']}';
    }
    if (response != null) {
      return 'HTTP ${response.statusCode}';
    }
    return error.message ?? error.type.name;
  }
  return error.toString();
}

extension ErrorContextExtension on BuildContext {
  void showMessage(String text) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void showError(Object error) => showMessage(errorMessage(error));

  /// Runs [action] and reports a failure in a SnackBar. Returns success.
  Future<bool> guard(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (success != null && mounted) {
        showMessage(success);
      }
      return true;
    } on Object catch (e) {
      if (mounted) {
        showError(e);
      }
      return false;
    }
  }
}
