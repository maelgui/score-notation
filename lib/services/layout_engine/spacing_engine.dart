import '../../model/measure.dart';
import '../../model/duration_fraction.dart';
import '../../utils/smufl/engraving_defaults.dart';
import '../../utils/measure_helper.dart';

/// Engine responsable du calcul des positions horizontales (spacing).
/// 
/// Calcule :
/// - La largeur naturelle d'une mesure
/// - Le poids rythmique de chaque durée
/// - Les positions X des notes
class SpacingEngine {
  SpacingEngine._();

  /// Calcule la largeur naturelle d'une mesure basée sur le rythme.
  /// 
  /// Trouve la plus petite subdivision de la mesure et calcule le nombre
  /// équivalent de subdivisions, puis multiplie par une largeur de base.
  static double computeNaturalWidth(
    Measure measure,
    double noteHeadWidth,
    double baseUnitFactor,
  ) {
    if (measure.events.isEmpty) {
      return noteHeadWidth * 3.0 + EngravingDefaults.spaceBeforeBarline * 2;
    }

    // Trouver la plus petite subdivision de la mesure
    final smallestSubdivision = measure.events
        .reduce((a, b) => a.actualDuration.reduce() < b.actualDuration.reduce() ? a : b)
        .actualDuration
        .reduce();

    // Calculer le nombre équivalent de cette subdivision dans la mesure
    final DurationFraction divisionResult =
        measure.totalDuration.reduce().divide(smallestSubdivision);
    final int equivalentNumberOfSubdivisions =
        (divisionResult.toDouble()).round();

    final double smallestSubdivisionWidth = noteHeadWidth * 1.5;
    return equivalentNumberOfSubdivisions * smallestSubdivisionWidth +
        EngravingDefaults.spaceBeforeBarline * 2;
  }

  /// Calcule le poids rythmique d'une durée.
  /// 
  /// Exemples :
  /// - noire = 1
  /// - croche = 2
  /// - double croche = 4
  /// 
  /// Le poids est inversement proportionnel à la durée (plus court = plus lourd).
  static double durationWeight(DurationFraction duration) {
    final reduced = duration.reduce();
    // Convertir la durée en poids : 1/4 = 1, 1/8 = 2, 1/16 = 4, etc.
    // weight = denominator / numerator (pour une fraction réduite)
    if (reduced.numerator == 0) return 0.0;
    return reduced.denominator / reduced.numerator;
  }

  /// Calcule les positions X des notes dans une mesure.
  /// 
  /// Les positions sont calculées proportionnellement à la durée de chaque note
  /// dans l'espace disponible (notesStartX à notesStartX + measureWidth).
  static List<({int eventIndex, double x})> computeNotePositions(
    Measure measure,
    double measureWidth,
    double notesStartX,
  ) {
    final List<({int eventIndex, double x})> positions = [];
    
    if (measure.events.isEmpty) {
      return positions;
    }

    final maxDuration = measure.maxDuration;
    final maxDurationValue = MeasureHelper.fractionToPosition(maxDuration);
    final notesSpan = measureWidth - EngravingDefaults.spaceBeforeBarline * 2;
    final actualNotesStartX = notesStartX + EngravingDefaults.spaceBeforeBarline;

    DurationFraction currentPosition = const DurationFraction(0, 1);
    
    for (int i = 0; i < measure.events.length; i++) {
      final event = measure.events[i];
      final positionValue = MeasureHelper.fractionToPosition(currentPosition);
      final double normalizedPosition = maxDurationValue > 0
          ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
          : 0.0;
      final double x = actualNotesStartX + normalizedPosition * notesSpan;
      
      positions.add((eventIndex: i, x: x));
      
      currentPosition = currentPosition.add(event.actualDuration);
    }

    return positions;
  }
}

