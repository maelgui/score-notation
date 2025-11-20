import '../../model/note_event.dart';
import '../../model/ornament.dart';

/// Structure pour une grace note layoutée.
class LayoutedGraceNote {
  const LayoutedGraceNote({
    required this.x,
    required this.y,
    required this.glyph,
    required this.stemX,
    required this.stemStartY,
    required this.stemEndY,
    required this.beamLevels,
  });

  final double x;
  final double y;
  final String glyph;
  final double stemX;
  final double stemStartY;
  final double stemEndY;
  final List<double> beamLevels; // Positions Y des beams
}

/// Engine responsable du calcul des grace notes (flams, drags, ruffs).
/// 
/// Calcule :
/// - Les offsets horizontaux pour flams/drags
/// - Les positions Y
/// - Les hampes et beams pour grace notes
class GraceEngine {
  GraceEngine._();

  /// Calcule les grace notes pour une note principale.
  static List<LayoutedGraceNote> computeGraceNotes(
    NoteEvent mainNote,
    double mainNoteX,
    double mainNoteY,
    double noteHeadWidth,
  ) {
    // TODO: Extraire depuis staff_painter.dart _drawSymbol (partie grace notes)
    throw UnimplementedError('GraceEngine.computeGraceNotes not yet implemented');
  }

  /// Calcule l'offset horizontal d'une grace note selon son ornement.
  static double computeGraceOffset(Ornament ornament, double noteHeadWidth) {
    // TODO: Implémenter le calcul d'offset
    throw UnimplementedError('GraceEngine.computeGraceOffset not yet implemented');
  }

  /// Calcule les positions pour un flam.
  static ({
    double x,
    double y,
    double stemX,
    double stemStartY,
    double stemEndY,
  }) computeFlamPosition(
    double mainNoteX,
    double mainNoteY,
    double noteHeadWidth,
  ) {
    // TODO: Implémenter le calcul de position pour flam
    throw UnimplementedError('GraceEngine.computeFlamPosition not yet implemented');
  }

  /// Calcule les positions pour un drag (deux grace notes).
  static ({
    double x1,
    double x2,
    double y,
    double stem1X,
    double stem2X,
    double stemStartY,
    double stemEndY,
    List<double> beamLevels,
  }) computeDragPositions(
    double mainNoteX,
    double mainNoteY,
    double noteHeadWidth,
  ) {
    // TODO: Implémenter le calcul de positions pour drag
    throw UnimplementedError('GraceEngine.computeDragPositions not yet implemented');
  }
}


