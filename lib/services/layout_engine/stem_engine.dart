import 'package:snare_notation/model/duration_fraction.dart';

import '../../model/note_event.dart';
import '../../utils/smufl/engraving_defaults.dart';

/// Engine responsable du calcul des hampes (stems).
/// 
/// Calcule :
/// - La direction de la hampe (haut/bas)
/// - La longueur de la hampe selon SMuFL
/// - Les positions X/Y des hampes
class StemEngine {
  StemEngine._();

  /// Calcule la position Y du centre d'une note.
  static double computeNoteCenterY(NoteEvent event, double staffY) {
    if (event.isRest) return staffY;
    final double offset = EngravingDefaults.noteLineOffset;
    return event.isAboveLine ? staffY - offset : staffY + offset;
  }

  /// Calcule les positions de la hampe pour une note avec son événement.
  /// 
  /// Pour les notes beamed, la hampe va jusqu'au dernier beam (beamBaseY).
  /// Pour les notes non-beamed, la hampe a une longueur fixe (stemLength).
  /// 
  /// Retourne (x, startY, endY)
  static ({double x, double startY, double endY}) computeStemPosition(
    double noteX,
    double noteY,
    NoteEvent event,
    double staffY,
    bool isBeamed,
    double? beamBaseY,
  ) {
    if (event.isRest || event.duration.reduce() == DurationFraction.whole) {
      return (x: noteX, startY: staffY, endY: staffY);
    }

    final double noteCenterY = computeNoteCenterY(event, staffY);
    final double stemX = noteX + EngravingDefaults.stemDownXOffset + EngravingDefaults.stemThickness / 2;
    
    final double stemStartY = noteCenterY;
    // Pour les notes beamed, la hampe va jusqu'au dernier beam (même logique que l'ancien code)
    // Pour les notes non-beamed, utiliser la longueur standard
    final double stemEndY = isBeamed && beamBaseY != null
        ? beamBaseY
        : stemStartY + EngravingDefaults.stemLength;

    return (x: stemX, startY: stemStartY, endY: stemEndY);
  }
}

