import '../model/duration_fraction.dart';
import '../model/note_event.dart';
import '../utils/music_symbols.dart';

/// Helpers pour travailler avec NoteEvent et obtenir les symboles SMuFL.
class NoteEventHelper {
  NoteEventHelper._();

  /// Retourne le symbole SMuFL à afficher pour un NoteEvent.
  static String getSymbol(NoteEvent event) {
    if (event.isRest) {
      // // Pour les silences, utiliser la durée pour déterminer le symbole
      // final duration = DurationConverter.fromFraction(event.duration);
      // if (duration != null) {
      //   return duration.restSymbol;
      // }
      // Si la durée n'est pas reconnue, essayer de déterminer le symbole directement
      final reduced = event.actualDuration.reduce();
      if (reduced == DurationFraction.whole) {
        return MusicSymbols.restWhole;
      } else if (reduced == DurationFraction.half) {
        return MusicSymbols.restHalf;
      } else if (reduced == DurationFraction.quarter) {
        return MusicSymbols.restQuarter;
      } else if (reduced == DurationFraction.eighth) {
        return MusicSymbols.restEighth;
      } else if (reduced == DurationFraction.sixteenth) {
        return MusicSymbols.restSixteenth;
      } else if (reduced == DurationFraction.thirtySecond) {
        return MusicSymbols.restThirtySecond;
      }
      return MusicSymbols.restQuarter; // Par défaut
    } else {
      // Pour les notes, toujours afficher la note selon sa durée
      // Les ornements (flam, drag) sont des notes de grâce qui s'ajoutent AVANT la note principale
      // Pour l'instant, on affiche la note principale avec l'accent si présent
      // TODO: Implémenter l'affichage des notes de grâce pour les ornements

      // Déterminer le symbole de base selon la durée
        // Si la durée n'est pas reconnue, essayer de déterminer le symbole directement
        final reduced = event.actualDuration.reduce();
        if (reduced == DurationFraction.whole) {
          return MusicSymbols.noteheadWhole;
        } else if (reduced == DurationFraction.half) {
          return MusicSymbols.noteheadHalf;
        } else if (reduced == DurationFraction.quarter) {
          return MusicSymbols.noteheadBlack;
        } else if (reduced == DurationFraction.eighth) {
          return MusicSymbols.noteheadBlack;
        } else if (reduced == DurationFraction.sixteenth) {
          return MusicSymbols.noteheadBlack;
        } else if (reduced == DurationFraction.thirtySecond) {
          return MusicSymbols.noteheadBlack;
        } else {
          return MusicSymbols.noteheadBlack; // Par défaut
        }

      // Pour les notes avec accent, on garde la note complète avec hampe
      // L'accent sera indiqué visuellement (MusicSymbols.accent est un signe posé au-dessus)
      // Pour l'instant, on retourne la note complète avec hampe pour préserver les hampes
      // TODO: Implémenter l'affichage de l'accent au-dessus de la note

      // Si un ornement est présent, on affiche quand même la note principale
      // (l'ornement devrait être affiché comme note de grâce séparée, mais c'est complexe)
      // Pour l'instant, on retourne la note principale
    }
  }
}
