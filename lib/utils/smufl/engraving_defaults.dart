import 'bravura_metrics.dart';

/// Valeurs par défaut pour l'engraving selon SMuFL.
/// 
/// Inspiré de MuseScore engraving defaults.
/// Ces valeurs sont utilisées par les engines de layout.
class EngravingDefaults {
  EngravingDefaults._();

  // === Dimensions de base ===
  static const double symbolFontSize = 36.0;
  static double get _smuflUnit => symbolFontSize / 4.0;
  static double get staffSpace => symbolFontSize / 4.0;

  // === Paramètres des grace notes ===
  static const double graceNoteScale = 0.7;
  static const double graceNoteStemScale = 0.7;
  static const double graceNoteHorizontalSpacingFactor = 1.2;
  static const double graceNoteVerticalOffsetFactor = 0;
  static const double graceSlashAngleDegrees = 30.0;
  static const double graceSlashLengthFactor = 4.0; // Multiplicateur de stemThickness

  // === Dimensions des hampes ===
  /// Épaisseur de la hampe (en pixels, convertie depuis SMuFL).
  static double get stemThickness {
    final smuflValue = BravuraMetrics.stemThickness ?? 0.12;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }

  /// Longueur standard des hampes selon SMuFL.
  /// stemLength = 3.5 * staffSpace
  static double get stemLength => 5 * _smuflUnit;

  /// Position X relative de la hampe pour stemDown (en pixels).
  static double get stemDownXOffset {
    final stemDownNW = BravuraMetrics.getGlyphAnchor('noteheadBlack', 'stemDownNW');
    final bBox = BravuraMetrics.getGlyphBBox('noteheadBlack');
    
    if (stemDownNW != null && bBox != null) {
      final centerX = (bBox['NE']![0] + bBox['SW']![0]) / 2.0;
      final offsetX = stemDownNW[0] - centerX;
      return BravuraMetrics.smuflToPixels(offsetX, symbolFontSize);
    }
    
    // Valeur par défaut si le chargement échoue
    return -0.59 * _smuflUnit;
  }

  // === Dimensions des beams ===
  /// Épaisseur d'un beam/ligature (en pixels, convertie depuis SMuFL).
  static double get beamThickness {
    final smuflValue = BravuraMetrics.beamThickness ?? 0.5;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }

  /// Espacement entre beams multiples (en pixels, convertie depuis SMuFL).
  static double get beamSpacing {
    final smuflValue = BravuraMetrics.beamSpacing ?? 0.25;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }

  // === Dimensions des notes ===
  /// Largeur approximative d'une tête de note (en pixels).
  /// Selon SMuFL, une tête de note noire a une largeur d'environ 1 staff space.
  static double get noteHeadWidth => 1.0 * _smuflUnit;

  /// Décalage vertical pour placer les notes au-dessus ou en dessous de la ligne.
  static double get noteLineOffset => 0.5 * _smuflUnit;

  // === Espacement ===
  /// Espacement avant la barre de mesure selon SMuFL.
  /// spaceBeforeBarline ≈ 0.25 × noteheadWidth
  static double get spaceBeforeBarline => 1 * noteHeadWidth;

  // === Facteurs de spacing ===
  static const double noteSpacingBaseUnitFactor = 2.0;
}


