import '../../model/note_event.dart';

/// Structure pour un roll layouté.
class LayoutedRoll {
  const LayoutedRoll({
    required this.x,
    required this.y,
    required this.angle,
    required this.slashCount,
    required this.slashLength,
  });

  final double x;
  final double y;
  final double angle; // En radians
  final int slashCount;
  final double slashLength;
}

/// Engine responsable du calcul des rolls (battements, tremolos).
/// 
/// Calcule :
/// - La position du roll
/// - L'angle
/// - Le nombre de slashes
class RollEngine {
  RollEngine._();

  /// Calcule le layout d'un roll pour une note.
  static LayoutedRoll computeRoll(
    NoteEvent note,
    double noteX,
    double noteY,
  ) {
    // TODO: Extraire depuis staff_painter.dart _drawSymbol (partie rolls)
    throw UnimplementedError('RollEngine.computeRoll not yet implemented');
  }
}


