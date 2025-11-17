import 'dart:convert';
import 'package:flutter/services.dart';

import 'logger.dart';

/// Classe pour charger et utiliser les métriques SMuFL depuis bravura_metadata.json
class BravuraMetrics {
  BravuraMetrics._();
  
  static Map<String, dynamic>? _metadata;
  static bool _loaded = false;
  
  /// Charge les métadonnées Bravura depuis les assets
  static Future<void> load() async {
    if (_loaded) return;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/bravura_metadata.json');
      _metadata = json.decode(jsonString) as Map<String, dynamic>;
      _loaded = true;
    } catch (e, stackTrace) {
      // Si le chargement échoue, on utilise des valeurs par défaut
      AppLogger.error(
        'Erreur lors du chargement de bravura_metadata.json',
        e,
        stackTrace,
      );
      _loaded = false;
    }
  }
  
  /// Récupère une valeur d'engraving depuis les métadonnées
  static double? getEngravingValue(String key) {
    if (!_loaded || _metadata == null) return null;
    
    final engravingDefaults = _metadata!['engravingDefaults'] as Map<String, dynamic>?;
    if (engravingDefaults == null) return null;
    
    final value = engravingDefaults[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
  
  /// Épaisseur de la hampe (stemThickness)
  static double? get stemThickness => getEngravingValue('stemThickness');
  
  /// Épaisseur d'un beam/ligature (beamThickness)
  static double? get beamThickness => getEngravingValue('beamThickness');
  
  /// Espacement entre beams multiples (beamSpacing)
  static double? get beamSpacing => getEngravingValue('beamSpacing');
  
  /// Récupère les coordonnées d'ancrage d'un glyphe depuis les métadonnées
  static List<double>? getGlyphAnchor(String glyphName, String anchorName) {
    if (!_loaded || _metadata == null) return null;
    
    final glyphsWithAnchors = _metadata!['glyphsWithAnchors'] as Map<String, dynamic>?;
    if (glyphsWithAnchors == null) return null;
    
    final glyph = glyphsWithAnchors[glyphName] as Map<String, dynamic>?;
    if (glyph == null) return null;
    
    final anchor = glyph[anchorName];
    if (anchor is List && anchor.length >= 2) {
      return [anchor[0].toDouble(), anchor[1].toDouble()];
    }
    return null;
  }
  
  /// Récupère la bounding box d'un glyphe depuis les métadonnées
  static Map<String, List<double>>? getGlyphBBox(String glyphName) {
    if (!_loaded || _metadata == null) return null;
    
    final glyphBBoxes = _metadata!['glyphBBoxes'] as Map<String, dynamic>?;
    if (glyphBBoxes == null) return null;
    
    final glyph = glyphBBoxes[glyphName] as Map<String, dynamic>?;
    if (glyph == null) return null;
    
    final bBoxNE = glyph['bBoxNE'] as List?;
    final bBoxSW = glyph['bBoxSW'] as List?;
    
    if (bBoxNE != null && bBoxNE.length >= 2 && bBoxSW != null && bBoxSW.length >= 2) {
      return {
        'NE': [bBoxNE[0].toDouble(), bBoxNE[1].toDouble()],
        'SW': [bBoxSW[0].toDouble(), bBoxSW[1].toDouble()],
      };
    }
    return null;
  }
  
  /// Convertit une valeur SMuFL (en staff space) en pixels
  /// Dans SMuFL, 1 staff space = symbolFontSize / 4 pour une portée standard
  static double smuflToPixels(double smuflValue, double fontSize) {
    // 1 staff space = fontSize / 4 (distance entre deux lignes de portée)
    const double staffSpaceRatio = 4.0;
    return smuflValue * (fontSize / staffSpaceRatio);
  }
}

