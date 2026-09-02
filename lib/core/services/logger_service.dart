import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

abstract class ILoggerService {
  void debug(String message, [Object? error, StackTrace? stackTrace]);
  void info(String message);
  void warning(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class LoggerService implements ILoggerService {
  const LoggerService();

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      dev.log('[DEBUG] $message', error: error, stackTrace: stackTrace, name: 'NovelsDestiny');
    }
  }

  @override
  void info(String message) {
    if (kDebugMode) {
      dev.log('[INFO] $message', name: 'NovelsDestiny');
    }
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log('[WARN] $message', error: error, stackTrace: stackTrace, name: 'NovelsDestiny');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log('[ERROR] $message', error: error, stackTrace: stackTrace, name: 'NovelsDestiny');
  }
}
