import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[$level] $message${error != null ? ' | $error' : ''}');
    }

    developer.log(
      message,
      name: 'NutriEasy',
      level: level == 'ERROR' ? 1000 : level == 'WARN' ? 900 : 800,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
