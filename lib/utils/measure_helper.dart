import '../model/duration_fraction.dart';

/// Helpers pour travailler avec Measure et NoteEvent.
class MeasureHelper {
  MeasureHelper._();

  /// Convertit une fraction de ronde en position en double (en noires).
  static double fractionToPosition(DurationFraction fraction) {
    // Convertir une fraction de ronde en noires
    // 1/4 de ronde = 1 noire
    return fraction.toDouble() * 4;
  }
}

