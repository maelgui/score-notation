/// Gère le layout d'une page A4 avec dimensions exactes.
/// 
/// Dimensions A4 :
/// - Portrait : 210 × 297 mm
/// - En points PostScript (PDF) : 595 × 842 pt (1 pt = 1/72 inch)
/// - En pixels @300 DPI : 2480 × 3508 px
class PageLayout {
  /// Type de rendu (PDF ou Image)
  enum RenderType {
    /// Rendu PDF avec unités PostScript (points)
    pdf,
    /// Rendu image haute résolution @300 DPI
    image,
  }

  const PageLayout({
    required this.renderType,
    this.marginMm = 20.0,
    this.staffSpacingPt = 100.0,
    this.zoom = 1.0,
  })  : assert(marginMm > 0, 'Margin must be positive'),
        assert(staffSpacingPt > 0, 'Staff spacing must be positive'),
        assert(zoom > 0, 'Zoom must be positive');

  final RenderType renderType;
  final double marginMm; // Marges en millimètres
  final double staffSpacingPt; // Espacement entre portées en points
  final double zoom;

  // === Dimensions A4 exactes ===

  /// Largeur A4 en millimètres
  static const double a4WidthMm = 210.0;

  /// Hauteur A4 en millimètres
  static const double a4HeightMm = 297.0;

  /// Largeur A4 en points PostScript (PDF)
  static const double a4WidthPt = 595.0;

  /// Hauteur A4 en points PostScript (PDF)
  static const double a4HeightPt = 842.0;

  /// Largeur A4 en pixels @300 DPI
  static const int a4WidthPx300 = 2480;

  /// Hauteur A4 en pixels @300 DPI
  static const int a4HeightPx300 = 3508;

  // === Conversions ===

  /// Convertit des millimètres en points PostScript
  /// 1 mm = 2.83465 pt (car 1 inch = 25.4 mm et 1 inch = 72 pt)
  static double mmToPt(double mm) => mm * 2.83465;

  /// Convertit des millimètres en pixels @300 DPI
  /// 1 mm = 11.811 px @300 DPI (car 1 inch = 25.4 mm et 1 inch = 300 px)
  static double mmToPx300(double mm) => mm * 11.811;

  /// Convertit des points en pixels @300 DPI
  /// 1 pt = 4.1667 px @300 DPI (car 1 inch = 72 pt et 1 inch = 300 px)
  static double ptToPx300(double pt) => pt * 4.1667;

  // === Dimensions de page ===

  /// Largeur de la page selon le type de rendu
  double get pageWidth {
    switch (renderType) {
      case RenderType.pdf:
        return a4WidthPt * zoom;
      case RenderType.image:
        return a4WidthPx300 * zoom;
    }
  }

  /// Hauteur de la page selon le type de rendu
  double get pageHeight {
    switch (renderType) {
      case RenderType.pdf:
        return a4HeightPt * zoom;
      case RenderType.image:
        return a4HeightPx300 * zoom;
    }
  }

  /// Marge selon le type de rendu
  double get margin {
    switch (renderType) {
      case RenderType.pdf:
        return mmToPt(marginMm) * zoom;
      case RenderType.image:
        return mmToPx300(marginMm) * zoom;
    }
  }

  /// Espacement entre portées selon le type de rendu
  double get staffSpacing {
    switch (renderType) {
      case RenderType.pdf:
        return staffSpacingPt * zoom;
      case RenderType.image:
        return ptToPx300(staffSpacingPt) * zoom;
    }
  }

  /// Largeur utile (pageWidth - 2*margin)
  double get usableWidth => pageWidth - 2 * margin;

  /// Hauteur utile (pageHeight - 2*margin)
  double get usableHeight => pageHeight - 2 * margin;

  /// Retourne la position Y du haut de la zone utile
  double get usableTop => margin;

  /// Retourne la position X du début de la zone utile
  double get usableLeft => margin;

  /// Retourne la position Y du bas de la zone utile
  double get usableBottom => pageHeight - margin;

  /// Retourne la position X de la fin de la zone utile
  double get usableRight => pageWidth - margin;

  /// Calcule la position Y pour une portée à un index donné
  /// 
  /// Les portées sont réparties verticalement dans la hauteur utile.
  /// [staffIndex] : index de la portée (0-based)
  /// [totalStaffs] : nombre total de portées
  /// 
  /// Retourne la position Y du centre de la ligne de portée.
  double staffYFor(int staffIndex, int totalStaffs) {
    if (totalStaffs <= 0) return usableTop + usableHeight / 2;
    if (totalStaffs == 1) return usableTop + usableHeight / 2;

    // Calculer l'espace total nécessaire pour toutes les portées
    final double totalStaffSpacing = (totalStaffs - 1) * staffSpacing;
    final double availableHeight = usableHeight - totalStaffSpacing;
    final double staffHeight = availableHeight / totalStaffs;

    // Position du centre de la première portée
    final double firstStaffCenterY = usableTop + staffHeight / 2;

    // Position du centre de la portée à l'index donné
    return firstStaffCenterY + staffIndex * (staffHeight + staffSpacing);
  }

  /// Calcule la position X pour une mesure dans une portée
  /// 
  /// [measureIndex] : index de la mesure dans la portée (0-based)
  /// [totalMeasures] : nombre total de mesures dans la portée
  /// [measureWidth] : largeur de la mesure
  /// 
  /// Retourne la position X du début de la mesure.
  double measureXFor({
    required int measureIndex,
    required int totalMeasures,
    required double measureWidth,
    double? spacing,
  }) {
    if (totalMeasures <= 0) return usableLeft;
    if (measureIndex < 0 || measureIndex >= totalMeasures) return usableLeft;

    final double barSpacing = spacing ?? (staffSpacing * 0.08); // 8% de l'espacement de portée

    // Calculer la largeur totale nécessaire
    double totalWidth = 0.0;
    for (int i = 0; i < totalMeasures; i++) {
      totalWidth += measureWidth;
      if (i < totalMeasures - 1) {
        totalWidth += barSpacing;
      }
    }

    // Centrer si la largeur totale est inférieure à la largeur utile
    double startX = usableLeft;
    if (totalWidth < usableWidth) {
      startX = usableLeft + (usableWidth - totalWidth) / 2;
    }

    // Calculer la position X de la mesure
    double x = startX;
    for (int i = 0; i < measureIndex; i++) {
      x += measureWidth + barSpacing;
    }

    return x;
  }

  /// Crée un PageLayout pour le rendu PDF
  static PageLayout forPdf({
    double marginMm = 20.0,
    double staffSpacingPt = 100.0,
    double zoom = 1.0,
  }) {
    return PageLayout(
      renderType: RenderType.pdf,
      marginMm: marginMm,
      staffSpacingPt: staffSpacingPt,
      zoom: zoom,
    );
  }

  /// Crée un PageLayout pour le rendu image @300 DPI
  static PageLayout forImage({
    double marginMm = 20.0,
    double staffSpacingPt = 100.0,
    double zoom = 1.0,
  }) {
    return PageLayout(
      renderType: RenderType.image,
      marginMm: marginMm,
      staffSpacingPt: staffSpacingPt,
      zoom: zoom,
    );
  }
}

