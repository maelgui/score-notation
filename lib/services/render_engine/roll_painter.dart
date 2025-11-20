import 'package:flutter/material.dart';
import '../layout_engine/roll_engine.dart';

/// Painter responsable du dessin des rolls (battements, tremolos).
/// 
/// Ne fait que du dessin, aucune logique de calcul.
class RollPainter {
  RollPainter._();

  /// Dessine un roll à partir de son layout.
  static void drawRoll(
    Canvas canvas,
    LayoutedRoll roll,
    Color color,
  ) {
    // TODO: Extraire depuis staff_painter.dart _drawSymbol (partie rolls)
    throw UnimplementedError('RollPainter.drawRoll not yet implemented');
  }
}


