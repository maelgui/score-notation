/// Codepoints SMuFL utiles pour la notation simplifiée.
///
/// Vous pouvez étendre cette classe avec davantage de symboles au fur et à mesure
/// des besoins (ornements, dynamiques, etc.).
class MusicSymbols {
  MusicSymbols._();

  // Articulations
  static const String accent = '\uE4A0'; // articAccent

  // Noteheads
  static const String noteheadWhole = '\uE0A2'; // Notehead white (tête seule)
  static const String noteheadHalf = '\uE0A3'; // Notehead white (tête seule)
  static const String noteheadBlack = '\uE0A4'; // Notehead black (tête seule)
  // Rudiments
  static const String flam = '\uE560';
  static const String drag = '\uE123';
  static const String roll = '\uE221'; // Tremolo2 (roulement avec 2 barres)
  
  // Rests (silences)
  static const String restWhole = '\uE4E2'; // Pause (ronde)
  static const String restHalf = '\uE4E3'; // Demi-pause (blanche)
  static const String restQuarter = '\uE4E5'; // Soupir (noire)
  static const String restEighth = '\uE4E6'; // Demi-soupir (croche)
  static const String restSixteenth = '\uE4E7'; // Quart de soupir (double croche)
  static const String restThirtySecond = '\uE4E8'; // Huitième de soupir (triple croche)
  
  // Notes complètes avec durées
  // Ronde (whole note) - notehead blanc sans hampe
  static const String wholeNote = '\uE1D2'; // NoteWhole (ronde complète)
  
  // Blanche (half note) - notehead blanc avec hampe
  static const String halfNote = '\uE1D4'; // NoteHalfDown (blanche avec hampe vers le bas)
  
  // Noire (quarter note) - notehead noir avec hampe
  static const String quarterNote = '\uE1D6'; // NoteQuarterDown (noire complète avec hampe vers le bas)
  static const String quarterNoteUp = '\uE1D5'; // NoteQuarterUp (noire complète avec hampe vers le haut)
  
  // Croche (eighth note)
  static const String eighthNote = '\uE1D8'; // NoteEighthDown
  static const String eighthNoteUp = '\uE1D7'; // NoteEighthUp
  
  // Double croche (sixteenth note)
  static const String sixteenthNote = '\uE1DA'; // NoteSixteenthDown
  static const String sixteenthNoteUp = '\uE1D9'; // NoteSixteenthUp
  
  // Triple croche (thirty-second note)
  static const String thirtySecondNote = '\uE1DC'; // NoteThirtySecondDown
  static const String thirtySecondNoteUp = '\uE1DB'; // NoteThirtySecondUp
  
  // Blanche (half note)
  static const String halfNoteUp = '\uE1D3'; // NoteHalfUp

  // Barres de mesure
  static const String barlineSingle = '\uE030'; // Barre simple
  static const String barlineFinal = '\uE032'; // Double barre finale

  // Time signatures (signatures rythmiques)
  // Range U+E080–U+E09F
  static const String timeSig0 = '\uE080';
  static const String timeSig1 = '\uE081';
  static const String timeSig2 = '\uE082';
  static const String timeSig3 = '\uE083';
  static const String timeSig4 = '\uE084';
  static const String timeSig5 = '\uE085';
  static const String timeSig6 = '\uE086';
  static const String timeSig7 = '\uE087';
  static const String timeSig8 = '\uE088';
  static const String timeSig9 = '\uE089';

  /// Retourne le glyphe SMuFL pour un chiffre de signature rythmique (0-9)
  static String timeSigDigit(int digit) {
    if (digit < 0 || digit > 9) {
      throw ArgumentError('Le chiffre doit être entre 0 et 9, reçu: $digit');
    }
    return String.fromCharCode(0xE080 + digit);
  }

  static const Map<String, String> byName = {
    'accentedNote': accent,
    'flam': flam,
    'drag': drag,
    'restQuarter': restQuarter,
    'eighthNote': eighthNote,
    'sixteenthNote': sixteenthNote,
    'thirtySecondNote': thirtySecondNote,
  };
}

/// Durées de notes disponibles
enum NoteDuration {
  whole, // Ronde
  half, // Blanche
  quarter, // Noire
  eighth, // Croche
  sixteenth, // Double croche
  thirtySecond, // Triple croche
}

extension WrittenDurationExtension on NoteDuration {
  NoteDuration? nextShorter() {
    final index = NoteDuration.values.indexOf(this);
    if (index + 1 < NoteDuration.values.length) {
      return NoteDuration.values[index + 1];
    }
    return null; // already shortest
  }

  String get symbol {
    switch (this) {
      case NoteDuration.whole:
        return MusicSymbols.wholeNote; // Ronde
      case NoteDuration.half:
        return MusicSymbols.halfNote; // Blanche
      case NoteDuration.quarter:
        // Noire : note complète avec hampe
        return MusicSymbols.quarterNote;
      case NoteDuration.eighth:
        return MusicSymbols.eighthNote;
      case NoteDuration.sixteenth:
        return MusicSymbols.sixteenthNote;
      case NoteDuration.thirtySecond:
        return MusicSymbols.thirtySecondNote;
    }
  }

  /// Retourne le symbole de silence correspondant à cette durée
  String get restSymbol {
    switch (this) {
      case NoteDuration.whole:
        return MusicSymbols.restWhole;
      case NoteDuration.half:
        return MusicSymbols.restHalf;
      case NoteDuration.quarter:
        return MusicSymbols.restQuarter;
      case NoteDuration.eighth:
        return MusicSymbols.restEighth;
      case NoteDuration.sixteenth:
        return MusicSymbols.restSixteenth;
      case NoteDuration.thirtySecond:
        return MusicSymbols.restThirtySecond;
    }
  }

  String get label {
    switch (this) {
      case NoteDuration.whole:
        return 'Ronde';
      case NoteDuration.half:
        return 'Blanche';
      case NoteDuration.quarter:
        return 'Noire';
      case NoteDuration.eighth:
        return 'Croche';
      case NoteDuration.sixteenth:
        return 'Double croche';
      case NoteDuration.thirtySecond:
        return 'Triple croche';
    }
  }

  double get durationValue {
    switch (this) {
      case NoteDuration.whole:
        return 4.0; // 4 temps
      case NoteDuration.half:
        return 2.0; // 2 temps
      case NoteDuration.quarter:
        return 1.0; // 1 temps
      case NoteDuration.eighth:
        return 0.5; // 1/2 temps
      case NoteDuration.sixteenth:
        return 0.25; // 1/4 temps
      case NoteDuration.thirtySecond:
        return 0.125; // 1/8 temps
    }
  }
}
