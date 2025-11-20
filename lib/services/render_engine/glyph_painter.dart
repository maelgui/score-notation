import 'package:flutter/material.dart';

/// Painter responsable du dessin des symboles SMuFL (glyphs).
/// 
/// Ne fait que du dessin, aucune logique de calcul.
class GlyphPainter {
  GlyphPainter._();

  /// Dessine un glyph SMuFL à la position donnée.
  /// 
  /// Retourne le Rect englobant le glyph dessiné.
  static Rect drawGlyph(
    Canvas canvas,
    String glyph,
    Offset position,
    double fontSize, {
    Color? color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color ?? Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);

    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      textPainter.width,
      textPainter.height,
    );
  }

  /// Dessine un glyph de grace note (taille réduite).
  static Rect drawGraceGlyph(
    Canvas canvas,
    String glyph,
    Offset position,
    double fontSize,
    double scaleFactor,
  ) {
    return drawGlyph(
      canvas,
      glyph,
      position,
      fontSize * scaleFactor,
    );
  }
}

