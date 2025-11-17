import 'bravura_metrics.dart';

/// Constantes globales pour l'application de notation de caisse claire.
class AppConstants {
  AppConstants._();

  // === Configuration par défaut ===
  static const int defaultBeatsPerBar = 4;
  static const int defaultTimeSignatureDenominator = 4;
  static const int defaultBarCount = 4;
  static const int minBarCount = 1;
  static const int maxBarCount = 16;

  // === Dimensions de la portée ===
  static const double staffPadding = 24.0;
  static const double barSpacing = 8.0;
  static const double barLineHeight = 28.0;
  
  // Espacement avant la barre de mesure selon SMuFL
  // spaceBeforeBarline ≈ 0.25 × noteheadWidth
  // Note: Comme les notes sont centrées sur leur position X, on doit ajouter
  // la moitié de la largeur de la note pour éviter que la note ne touche la barre
  static double get spaceBeforeBarline => 2 * noteHeadWidth + (noteHeadWidth / 2);

  // === Dimensions des symboles musicaux ===
  static const double symbolFontSize = 36.0;
  static const double timeSignatureFontSize = 22.0;
  static const double timeSignatureLineHeight = 1.1;
  static const double timeSignatureSpacing = 8.0;
  
  // === Paramètres des grace notes ===
  static const double graceNoteScale = 0.7;
  static const double graceNoteStemScale = 0.7;
  static const double graceNoteHorizontalSpacingFactor = 1.2;
  static const double graceNoteVerticalOffsetFactor = 0;
  static const double graceSlashAngleDegrees = 30.0;
  static const double graceSlashLengthFactor = 4.0; // Multiplicateur de stemThickness

  // === Dimensions de sélection ===
  static const double selectionBorderWidth = 2.0;
  static const double selectionBorderRadius = 4.0;
  static const double selectionPadding = 4.0;

  // === Dimensions des ornements ===
  static const double ornamentIndicatorRadius = 3.0;
  static const double ornamentIndicatorOffset = 8.0;

  // === Couleurs ===
  static const int selectionColorValue = 0xFF2196F3; // Blue
  static const int ornamentIndicatorColorValue = 0xFFFF9800; // Orange

  // === Tolérances et seuils ===
  static const double positionTolerance = 0.001;
  static const double noteSelectionTolerance = 0.125; // 1/8 de noire
  static const double hitRadiusMultiplier = 0.5;
  static const double hitRadiusPadding = 4.0;

  // === Espacement UI ===
  static const double defaultHorizontalPadding = 16.0;
  static const double defaultVerticalPadding = 8.0;
  static const double dividerHeight = 1.0;
  static const double actionButtonSpacing = 8.0;

  // === Métriques SMuFL pour l'engraving ===
  // Ces valeurs sont chargées depuis bravura_metadata.json via BravuraMetrics
  // Source: https://github.com/steinbergmedia/bravura/blob/master/redist/bravura_metadata.json
  //
  // Note: Les unités SMuFL sont en "staff space" (espace de portée).
  // Pour Bravura, 1 staff space = symbolFontSize / 4 (distance entre deux lignes de portée)
  
  // Facteur de conversion SMuFL vers pixels
  // Dans SMuFL, les valeurs sont relatives à un "staff space"
  // Pour une portée standard, 1 staff space = symbolFontSize / 4
  static double get _smuflUnit => symbolFontSize / 4.0;
  static double get staffSpace => symbolFontSize / 4.0;
  
  // Épaisseur de la hampe (en pixels, convertie depuis SMuFL)
  // Utilise la valeur depuis bravura_metadata.json si disponible, sinon valeur par défaut
  static double get stemThickness {
    final smuflValue = BravuraMetrics.stemThickness ?? 0.12;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }
  
  // Épaisseur d'un beam/ligature (en pixels, convertie depuis SMuFL)
  // Utilise la valeur depuis bravura_metadata.json si disponible, sinon valeur par défaut
  static double get beamThickness {
    final smuflValue = BravuraMetrics.beamThickness ?? 0.5;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }
  
  // Espacement entre beams multiples (en pixels, convertie depuis SMuFL)
  // Utilise la valeur depuis bravura_metadata.json si disponible, sinon valeur par défaut
  static double get beamSpacing {
    final smuflValue = BravuraMetrics.beamSpacing ?? 0.25;
    return BravuraMetrics.smuflToPixels(smuflValue, symbolFontSize);
  }
  
  // Position X relative de la hampe pour stemDown (en pixels)
  // Utilise les vraies valeurs SMuFL depuis bravura_metadata.json
  // Pour noteheadBlack: stemDownNW est à [0.0, -0.168] et bBox est [0.0, -0.5] à [1.18, 0.5]
  // Le centre de la note est à X = (1.18 + 0.0) / 2 = 0.59
  // L'offset depuis le centre est donc: 0.0 - 0.59 = -0.59 staff space
  static double get stemDownXOffset {
    // Si un ajustement manuel est défini, l'utiliser
    if (stemDownXOffsetManual != 0.0) {
      return stemDownXOffsetManual * _smuflUnit;
    }
    
    // Sinon, utiliser les valeurs SMuFL
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
  
  // Longueur standard des hampes selon SMuFL
  // stemLength = 3.5 * staffSpace
  static double get stemLength => 5 * _smuflUnit;
  
  // Largeur approximative d'une tête de note (en pixels)
  // Selon SMuFL, une tête de note noire a une largeur d'environ 1 staff space
  static double get noteHeadWidth => 1.0 * _smuflUnit;

  // Décalage vertical pour placer les notes au-dessus ou en dessous de la ligne
  // Utilise 1 espace de portée (1 staff space)
  static double get noteLineOffset => 0.5 * _smuflUnit;
  
  // ============================================
  // AJUSTEMENTS MANUELS (si l'affichage n'est pas correct)
  // ============================================
  // Si les hampes sont trop à gauche/droite, ajustez cette valeur:
  // - Valeur plus négative (ex: -0.7) = hampes plus à gauche
  // - Valeur moins négative (ex: -0.4) = hampes plus à droite
  // - Valeur positive = hampes à droite de la note
  static double get stemDownXOffsetManual => 0.0; // 0.0 = utilise la valeur SMuFL automatique
  
  // Si les beams sont trop bas/haut, ajustez cette valeur:
  // - Valeur plus grande (ex: 4.0) = beams plus bas
  // - Valeur plus petite (ex: 3.0) = beams plus haut
  static double get beamYOffsetDownManual => 0.0; // 0.0 = utilise la valeur SMuFL automatique
}

