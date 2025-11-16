import 'package:flutter/material.dart';

import 'logger.dart';

/// Gestionnaire d'erreurs centralisé pour l'application.
class ErrorHandler {
  ErrorHandler._();

  /// Affiche une erreur à l'utilisateur via un SnackBar.
  /// 
  /// [context] : Le BuildContext pour afficher le SnackBar
  /// [message] : Message d'erreur à afficher
  /// [error] : L'exception (optionnel, pour le logging)
  /// [stackTrace] : Stack trace (optionnel, pour le logging)
  static void showError(
    BuildContext? context,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Logger l'erreur
    AppLogger.error(message, error, stackTrace);

    // Afficher à l'utilisateur si le contexte est disponible
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Affiche un avertissement à l'utilisateur via un SnackBar.
  static void showWarning(
    BuildContext? context,
    String message, [
    Object? error,
  ]) {
    AppLogger.warning(message, error);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Affiche un message d'information à l'utilisateur via un SnackBar.
  static void showInfo(
    BuildContext? context,
    String message,
  ) {
    AppLogger.info(message);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Gère une exception de manière centralisée.
  /// 
  /// Log l'erreur et affiche un message à l'utilisateur.
  static void handleException(
    BuildContext? context,
    Object error,
    StackTrace stackTrace, {
    String? customMessage,
  }) {
    final message = customMessage ?? 'Une erreur est survenue';
    showError(context, message, error, stackTrace);
  }
}

