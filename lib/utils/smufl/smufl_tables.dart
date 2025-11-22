import '../../model/duration_fraction.dart';
import '../../model/ornament.dart';

/// Tables de correspondance SMuFL.
///
/// Mapping entre les entités musicales et les glyphs SMuFL.
class SmuflTables {
  SmuflTables._();

  /// Retourne le glyph SMuFL pour une durée donnée.
  ///
  /// Exemples :
  /// - whole note (ronde) → "noteWhole"
  /// - half note (blanche) → "noteHalfUp"
  /// - quarter note (noire) → "noteQuarterUp"
  static String? getGlyphForDuration(DurationFraction duration) {
    // TODO: Implémenter le mapping durée → glyph
    // Utiliser NoteEventHelper.getSymbol comme référence
    throw UnimplementedError('SmuflTables.getGlyphForDuration not yet implemented');
  }

  /// Retourne le glyph SMuFL pour un ornement donné.
  static String? getGlyphForOrnament(Ornament ornament) {
    // TODO: Implémenter le mapping ornament → glyph
    throw UnimplementedError('SmuflTables.getGlyphForOrnament not yet implemented');
  }

  /// Retourne le glyph SMuFL pour un silence de durée donnée.
  static String? getGlyphForRest(DurationFraction duration) {
    // TODO: Implémenter le mapping silence → glyph
    throw UnimplementedError('SmuflTables.getGlyphForRest not yet implemented');
  }
}
