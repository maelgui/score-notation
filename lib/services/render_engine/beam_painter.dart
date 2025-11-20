import 'package:flutter/material.dart';
import '../layout_engine/measure_layout_result.dart';

/// Painter responsable du dessin des beams (ligatures) et hampes.
/// 
/// Ne fait que du dessin, aucune logique de calcul.
class BeamPainter {
  BeamPainter._();

  /// Dessine un segment de beam.
  static void drawBeamSegment(
    Canvas canvas,
    LayoutedBeamSegment segment,
    double beamThickness,
    Color color,
  ) {
    final beamPaint = Paint()
      ..color = color
      ..strokeWidth = beamThickness
      ..strokeCap = StrokeCap.butt; // Extrémités nettes pour les ligatures

    canvas.drawLine(
      Offset(segment.startX, segment.y),
      Offset(segment.endX, segment.y),
      beamPaint,
    );
  }

  /// Dessine une hampe.
  static void drawStem(
    Canvas canvas,
    double x,
    double startY,
    double endY,
    double thickness,
    Color color,
  ) {
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, startY),
      Offset(x, endY),
      stemPaint,
    );
  }
}

