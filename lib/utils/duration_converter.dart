import '../model/duration_fraction.dart';
import '../utils/music_symbols.dart';

/// Helpers pour convertir entre NoteDuration et DurationFraction.
class DurationConverter {
  DurationConverter._();

  /// Convertit un NoteDuration en DurationFraction.
  static DurationFraction toFraction(NoteDuration duration) {
    switch (duration) {
      case NoteDuration.whole:
        return DurationFraction.whole;
      case NoteDuration.half:
        return DurationFraction.half;
      case NoteDuration.quarter:
        return DurationFraction.quarter;
      case NoteDuration.eighth:
        return DurationFraction.eighth;
      case NoteDuration.sixteenth:
        return DurationFraction.sixteenth;
      case NoteDuration.thirtySecond:
        return DurationFraction.thirtySecond;
    }
  }

  /// Convertit une DurationFraction en NoteDuration si possible.
  /// Retourne null si la fraction ne correspond pas à une durée standard.
  static NoteDuration? fromFraction(DurationFraction fraction) {
    final reduced = fraction.reduce();
    if (reduced == DurationFraction.whole) {
      return NoteDuration.whole;
    } else if (reduced == DurationFraction.half) {
      return NoteDuration.half;
    } else if (reduced == DurationFraction.quarter) {
      return NoteDuration.quarter;
    } else if (reduced == DurationFraction.eighth) {
      return NoteDuration.eighth;
    } else if (reduced == DurationFraction.sixteenth) {
      return NoteDuration.sixteenth;
    } else if (reduced == DurationFraction.thirtySecond) {
      return NoteDuration.thirtySecond;
    }
    return null;
  }

  /// Convertit une valeur double (en noires) en DurationFraction.
  /// 
  /// Retourne toujours une fraction unitaire (1/n) pour les durées standard.
  static DurationFraction fromDouble(double value) {
    // Convertir en fraction de noire (1.0 = 1/4 de ronde)
    // On cherche la fraction la plus proche parmi les durées standard
    if ((value - 4.0).abs() < 0.001) {
      return DurationFraction.whole;
    } else if ((value - 2.0).abs() < 0.001) {
      return DurationFraction.half;
    } else if ((value - 1.0).abs() < 0.001) {
      return DurationFraction.quarter;
    } else if ((value - 0.5).abs() < 0.001) {
      return DurationFraction.eighth;
    } else if ((value - 0.25).abs() < 0.001) {
      return DurationFraction.sixteenth;
    } else if ((value - 0.125).abs() < 0.001) {
      return DurationFraction.thirtySecond;
    }
    // Pour les autres valeurs, on convertit en fraction de noire
    // 1.0 = 1/4, donc value = value/4
    // On multiplie par 4 pour avoir la fraction de ronde
    // On normalise pour obtenir une fraction unitaire si possible
    final int numerator = (value * 4).round();
    final fraction = DurationFraction(numerator, 4).reduce();
    // Essayer de normaliser en fraction unitaire
    final normalized = fraction.normalizeToUnitFraction();
    return normalized ?? fraction;
  }
}

