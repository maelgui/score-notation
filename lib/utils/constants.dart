/// Constantes globales pour l'application de notation de caisse claire.
/// 
/// Note: Les constantes SMuFL et d'engraving sont maintenant dans `EngravingDefaults`.
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
  static const double barLineHeight = 28.0;
  static const double staffSpacing = 80.0; // Espacement vertical entre les portées

  // === Dimensions des symboles musicaux (UI) ===
  static const double timeSignatureFontSize = 22.0;
  static const double timeSignatureLineHeight = 1.1;
  static const double timeSignatureSpacing = 8.0;

  // === Dimensions de sélection ===
  static const double selectionBorderWidth = 2.0;
  static const double selectionBorderRadius = 4.0;
  static const double selectionPadding = 4.0;
  static const double cursorWidth = 1.0;
  static const int cursorColorValue = 0xFF1565C0;
  static const int selectionFillColorValue = 0x331565C0;

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
}

