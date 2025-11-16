import '../model/duration_fraction.dart';
import '../model/note_event.dart';
import '../utils/duration_converter.dart';
import '../utils/measure_helper.dart';

/// Helpers pour remplir un espace avec des silences de durées standard.
class RestFiller {
  RestFiller._();

  /// Divise un espace en durées standard (1/4, 1/8, 1/16, 1/32) en utilisant
  /// les plus grandes unités possibles en premier.
  /// Retourne une liste de NoteEvent (silences) qui remplissent l'espace.
  static List<NoteEvent> fillSpaceWithRests(DurationFraction space) {
    final rests = <NoteEvent>[];
    final spaceValue = MeasureHelper.fractionToPosition(space);
    
    if (spaceValue <= 0.001) {
      return rests;
    }

    // Diviser l'espace en utilisant les plus grandes unités possibles
    final parts = _divideSpaceWithLargestUnits(spaceValue);
    
    for (final part in parts) {
      // Les parts sont toujours des valeurs exactes (1.0, 0.5, 0.25, 0.125)
      // donc on peut directement utiliser les constantes
      DurationFraction partFraction;
      if ((part - 1.0).abs() < 0.001) {
        partFraction = DurationFraction.quarter;
      } else if ((part - 0.5).abs() < 0.001) {
        partFraction = DurationFraction.eighth;
      } else if ((part - 0.25).abs() < 0.001) {
        partFraction = DurationFraction.sixteenth;
      } else if ((part - 0.125).abs() < 0.001) {
        partFraction = DurationFraction.thirtySecond;
      } else {
        // Fallback (ne devrait jamais arriver)
        partFraction = DurationConverter.fromDouble(part);
      }
      rests.add(NoteEvent(
        duration: partFraction,
        isRest: true,
      ));
    }

    return rests;
  }

  /// Divise un espace en utilisant les plus grandes unités possibles en premier.
  /// Exemple : 0.75 -> [0.5, 0.25] (demi puis quart)
  /// Principe : prendre la plus grande unité qui tient, puis diviser récursivement le reste
  static List<double> _divideSpaceWithLargestUnits(double space) {
    if (space <= 0.001) {
      return [];
    }

    // Unités valides : 1.0, 0.5, 0.25, 0.125 (du plus grand au plus petit)
    const List<double> validUnits = [1.0, 0.5, 0.25, 0.125];

    // Prendre la plus grande unité qui tient et diviser récursivement le reste
    for (final unit in validUnits) {
      if (space >= unit - 0.001) {
        final double remaining = space - unit;
        final List<double> result = [unit];
        if (remaining > 0.001) {
          result.addAll(_divideSpaceWithLargestUnits(remaining));
        }
        // Retourner dans l'ordre : plus grand d'abord
        return result;
      }
    }

    // Si aucune unité ne convient, retourner l'espace tel quel (cas très rare)
    return [space];
  }
}


