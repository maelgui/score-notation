import 'package:flutter/foundation.dart';

/// Système de logging simple pour l'application.
/// 
/// Utilise `debugPrint` en mode debug et peut être étendu pour utiliser
/// un package de logging plus avancé (comme `logger`) si nécessaire.
class AppLogger {
  AppLogger._();

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      debugPrint('🐛 [DEBUG] $message\nError: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    } else {
      debugPrint('🐛 [DEBUG] $message');
    }
  }

  static void info(String message) {
    debugPrint('ℹ️ [INFO] $message');
  }

  static void warning(String message, [Object? error]) {
    if (error != null) {
      debugPrint('⚠️ [WARNING] $message\nError: $error');
    } else {
      debugPrint('⚠️ [WARNING] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      debugPrint('❌ [ERROR] $message\nError: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    } else {
      debugPrint('❌ [ERROR] $message');
    }
  }
}

