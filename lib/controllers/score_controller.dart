import '../model/accent.dart';
import '../model/duration_fraction.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../model/score.dart';
import '../model/time_signature.dart';
import '../model/measure.dart';
import '../utils/measure_editor.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/duration_converter.dart';
import '../utils/music_symbols.dart';
import '../widgets/unified_palette.dart';

/// Contrôleur pour gérer la logique métier de la partition.
///
/// Extrait toute la logique de manipulation de la partition du widget UI.
class ScoreController {
  ScoreController({
    required StorageService storageService,
    int defaultBarCount = AppConstants.defaultBarCount,
  }) : _storageService = storageService,
       _defaultBarCount = defaultBarCount;

  final StorageService _storageService;
  final int _defaultBarCount;

  Score _score = const Score(measures: []);

  /// Score actuel (lecture seule depuis l'extérieur).
  Score get score => _score;

  /// Initialise le contrôleur avec une partition par défaut ou chargée.
  Future<void> initialize() async {
    _score = _createDefaultScore(_defaultBarCount);
    await loadScore();
  }

  /// Charge la partition depuis le stockage.
  Future<void> loadScore() async {
    try {
      final loadedScore = await _storageService.loadScore();
      _score = loadedScore.measures.isEmpty
          ? _createDefaultScore(_defaultBarCount)
          : _enforceScoreIntegrity(loadedScore);
    } catch (e) {
      // En cas d'erreur, utiliser une partition par défaut
      _score = _createDefaultScore(_defaultBarCount);
      rethrow;
    }
  }

  /// Sauvegarde la partition actuelle.
  Future<void> saveScore() async {
    await _storageService.saveScore(_score);
  }

  /// Efface la partition actuelle.
  Future<void> clearScore() async {
    _score = _createDefaultScore(_score.measures.length);
    await _storageService.clearScore();
  }

  /// Change le nombre de mesures.
  void setMeasureCount(int newCount) {
    if (newCount < AppConstants.minBarCount ||
        newCount > AppConstants.maxBarCount) {
      return;
    }

    if (newCount > _score.measures.length) {
      // Ajouter des mesures
      final newMeasures = <Measure>[..._score.measures];
      while (newMeasures.length < newCount) {
        newMeasures.add(_createDefaultMeasure(newMeasures.length + 1));
      }
      _score = _score.copyWith(measures: newMeasures);
    } else if (newCount < _score.measures.length) {
      // Retirer des mesures
      final newMeasures = _score.measures.sublist(0, newCount);
      _score = _score.copyWith(measures: newMeasures);
    }
    // Normaliser les numéros de mesures après modification
    _score = _normalizeMeasureNumbers(_score);
  }

  /// Change le nombre de mesures par ligne.
  void setMeasuresPerLine(int measuresPerLine) {
    if (measuresPerLine < 1 || measuresPerLine > 16) {
      return;
    }
    _score = _score.copyWith(measuresPerLine: measuresPerLine);
  }

  /// Ajoute une note dans une mesure.
  ///
  /// [measureIndex] : Index de la mesure (0-based)
  /// [eventIndex] : Index de l'événement à remplacer
  /// [selectedSymbol] : Symbole sélectionné (pour déterminer l'ornement/accent)
  /// [selectedDuration] : Durée de la note à placer
  Future<void> addNoteAtBeat(
    int measureIndex, {
    required int eventIndex,
    required SelectedSymbol selectedSymbol,
    required NoteDuration selectedDuration,
  }) async {
    if (measureIndex < 0 || measureIndex >= _score.measures.length) {
      return;
    }

    final measure = _score.measures[measureIndex];

    // Vérifier que l'index est valide
    if (eventIndex < 0 || eventIndex > measure.events.length) {
      return;
    }

    // Cas spécial : triolet
    if (selectedSymbol == SelectedSymbol.triplet) {
      await _addTriplet(measureIndex, eventIndex, selectedDuration);
      return;
    }

    // Déterminer la durée de l'événement à placer
    final DurationFraction eventDuration = DurationConverter.toFraction(
      selectedDuration,
    );

    final bool isRest = selectedSymbol == SelectedSymbol.rest;
    final bool placeAboveLine = selectedSymbol == SelectedSymbol.right;

    // Pas d'ornement ni d'accent
    final Ornament? ornament = null;
    final Accent? accent = null;

    // Créer le NoteEvent
    final noteEvent = NoteEvent(
      actualDuration: eventDuration,
      writenDuration: selectedDuration,
      isRest: isRest,
      ornament: ornament,
      accent: accent,
      isAboveLine: placeAboveLine,
    );

    // Insérer la note dans la mesure (remplace toujours l'événement à l'index)
    final updatedMeasure = MeasureEditor.insertNotes(
      measure,
      eventIndex,
      [noteEvent],
    );

    final updatedMeasures = <Measure>[..._score.measures];
    updatedMeasures[measureIndex] = updatedMeasure;
    _score = _score.copyWith(measures: updatedMeasures);

    await saveScore();
  }

  /// Ajoute un triolet de la durée sélectionnée.
  Future<void> _addTriplet(
    int measureIndex,
    int eventIndex,
    NoteDuration selectedDuration,
  ) async {
    final measure = _score.measures[measureIndex];

    // Durée de base du triolet
    final baseDuration = DurationConverter.toFraction(selectedDuration);
    final writenDuration = selectedDuration.nextShorter();

    if (writenDuration == null) {
      return;
    }

    // Durée de chaque note du triolet (2/3 de la durée de base)
    final tripletNoteDuration = DurationFraction(
      baseDuration.numerator,
      baseDuration.denominator * 3,
    );

    // Créer 3 notes du triolet (alternant droite/gauche)
    final tripletNotes = [
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        isRest: false,
        isAboveLine: true, // Droite
      ),
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        isRest: false,
        isAboveLine: false, // Gauche
      ),
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        isRest: false,
        isAboveLine: true, // Droite
      ),
    ];

    // Insérer les 3 notes du triolet
    Measure updatedMeasure = measure;
    updatedMeasure = MeasureEditor.insertNotes(
      updatedMeasure,
      eventIndex,
      tripletNotes,
    );

    final updatedMeasures = <Measure>[..._score.measures];
    updatedMeasures[measureIndex] = updatedMeasure;
    _score = _score.copyWith(measures: updatedMeasures);

    await saveScore();
  }

  /// Modifie une note existante à l'index donné dans une mesure.
  ///
  /// [measureIndex] : Index de la mesure (0-based)
  /// [eventIndex] : Index de l'événement à modifier
  /// [accent] : Accent à appliquer (null pour retirer)
  /// [ornament] : Ornement à appliquer (null pour retirer)
  Future<void> modifyNote(
    int measureIndex,
    int eventIndex, {
    Accent? accent,
    Ornament? ornament,
  }) async {
    if (measureIndex < 0 || measureIndex >= _score.measures.length) {
      return;
    }

    final measure = _score.measures[measureIndex];

    // Vérifier que l'index est valide
    if (eventIndex < 0 || eventIndex >= measure.events.length) {
      return;
    }

    final event = measure.events[eventIndex];

    // Ne modifier que les notes (pas les silences)
    if (event.isRest) {
      return;
    }

    // Créer une copie modifiée de l'événement
    final modifiedEvent = event.copyWith(accent: accent, ornament: ornament);

    // Remplacer l'événement dans la mesure
    final updatedEvents = <NoteEvent>[...measure.events];
    updatedEvents[eventIndex] = modifiedEvent;

    final updatedMeasure = measure.copyWith(events: updatedEvents);
    final updatedMeasures = <Measure>[..._score.measures];
    updatedMeasures[measureIndex] = updatedMeasure;
    _score = _score.copyWith(measures: updatedMeasures);

    await saveScore();
  }

  /// Trouve la note la plus proche d'une position donnée.
  ///
  /// Retourne la position exacte de la note trouvée, ou null si aucune note n'est proche.
  DurationFraction? findClosestNotePosition(int measureIndex, double position) {
    if (measureIndex < 0 || measureIndex >= _score.measures.length) {
      return null;
    }

    final measure = _score.measures[measureIndex];
    final maxDuration = measure.maxDuration;
    final maxDurationValue = _fractionToPosition(maxDuration);
    final clampedPosition = position.clamp(0.0, maxDurationValue);

    // Convertir la position en DurationFraction
    final positionFraction = DurationConverter.fromDouble(clampedPosition);

    // Vérifier s'il y a une note à cette position
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(
      measure,
    );

    // Trouver l'événement le plus proche de la position cliquée
    DurationFraction? closestPosition;
    double minDistance = double.infinity;

    for (final entry in eventsWithPositions) {
      // Calculer la distance en comparant les positions réduites
      final entryPosReduced = entry.position.reduce();
      final clickedPosReduced = positionFraction.reduce();
      final distance =
          (entryPosReduced.toDouble() - clickedPosReduced.toDouble()).abs();

      // Tolérance : un huitième de noire
      if (distance < minDistance &&
          distance < AppConstants.noteSelectionTolerance) {
        minDistance = distance;
        closestPosition = entry.position;
      }
    }

    return closestPosition;
  }

  /// Vérifie si la partition contient des notes (non-silences).
  bool hasNotes() {
    return _score.measures.any((measure) {
      return measure.events.any((e) => !e.isRest);
    });
  }

  // === Méthodes privées ===

  Score _createDefaultScore(int count, {int measuresPerLine = 4}) {
    return Score(
      measures: List.generate(
        count,
        (index) => _createDefaultMeasure(index + 1),
      ),
      measuresPerLine: measuresPerLine,
    );
  }

  Measure _createDefaultMeasure(int number) {
    final timeSignature = TimeSignature(
      AppConstants.defaultBeatsPerBar,
      AppConstants.defaultTimeSignatureDenominator,
    );
    return Measure.empty(timeSignature, number);
  }

  Score _enforceScoreIntegrity(Score score) {
    // Normaliser les numéros de mesures pour s'assurer qu'ils sont corrects
    return _normalizeMeasureNumbers(score);
  }

  /// Normalise les numéros de mesures pour qu'ils correspondent à leur index (1-based).
  Score _normalizeMeasureNumbers(Score score) {
    final normalizedMeasures = score.measures.asMap().entries.map((entry) {
      final index = entry.key;
      final measure = entry.value;
      // Si le numéro est déjà correct, on le garde, sinon on le met à jour
      if (measure.number == index + 1) {
        return measure;
      }
      return measure.copyWith(number: index + 1);
    }).toList();
    return score.copyWith(measures: normalizedMeasures);
  }

  double _fractionToPosition(DurationFraction fraction) {
    // Convertir une fraction de ronde en noires
    // 1/4 de ronde = 1 noire
    return fraction.toDouble() * 4;
  }
}
