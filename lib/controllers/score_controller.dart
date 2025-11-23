import '../model/accent.dart';
import '../model/duration_fraction.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../model/score.dart';
import '../model/score_metadata.dart';
import '../model/tuplet_info.dart';
import '../model/measure.dart';
import '../utils/measure_editor.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/duration_converter.dart';
import '../utils/music_symbols.dart';
import '../widgets/unified_palette.dart';

/// Contrôleur pour gérer une partition avec ses métadonnées.
class ScoreController {
  ScoreController({
    required StorageService storageService,
    String? scoreId,
    ScoreMetadata? metadata,
  }) : _storageService = storageService,
       _scoreId = scoreId,
       _metadata = metadata;

  final StorageService _storageService;

  String? _scoreId;
  ScoreMetadata? _metadata;
  Score _score = const Score(measures: []);

  /// ID de la partition actuelle.
  String? get scoreId => _scoreId;

  /// Métadonnées de la partition actuelle.
  ScoreMetadata? get metadata => _metadata;

  /// Score actuel (lecture seule depuis l'extérieur).
  Score get score => _score;

  /// Initialise le contrôleur avec une partition existante ou nouvelle.
  Future<void> initialize() async {
    if (_scoreId != null) {
      await loadScore(_scoreId!);
    } else {
      _score = Score.defaultScore();
    }
  }

  /// Charge une partition spécifique par son ID.
  Future<void> loadScore(String scoreId) async {
    try {
      final loadedScore = await _storageService.loadScore(scoreId);
      if (loadedScore != null) {
        _score = _enforceScoreIntegrity(loadedScore);
        _scoreId = scoreId;

        // Charger les métadonnées si elles ne sont pas déjà présentes
        if (_metadata == null) {
          final allMetadata = await _storageService.loadScoresMetadata();
          _metadata = allMetadata.firstWhere(
            (m) => m.id == scoreId,
            orElse: () => ScoreMetadata(
              id: scoreId,
              title: 'Partition sans titre',
              createdAt: DateTime.now(),
              lastModified: DateTime.now(),
            ),
          );
        }
      } else {
        _score = Score.defaultScore();
      }
    } catch (e) {
      // En cas d'erreur, utiliser une partition par défaut
      _score = Score.defaultScore();
      rethrow;
    }
  }

  /// Sauvegarde la partition actuelle avec ses métadonnées.
  Future<void> saveScore() async {
    if (_scoreId == null || _metadata == null) {
      throw Exception('Impossible de sauvegarder: ID ou métadonnées manquants');
    }

    // Mettre à jour la date de dernière modification
    _metadata = _metadata!.copyWith(lastModified: DateTime.now());

    await _storageService.saveScore(_scoreId!, _score, _metadata!);
  }

  /// Crée une nouvelle partition avec métadonnées.
  Future<void> createNewScore(ScoreMetadata metadata, Score score) async {
    _scoreId = metadata.id;
    _metadata = metadata;
    _score = score;
    await saveScore();
  }

  /// Met à jour les métadonnées de la partition.
  Future<void> updateMetadata(ScoreMetadata newMetadata) async {
    _metadata = newMetadata.copyWith(lastModified: DateTime.now());
    if (_scoreId != null) {
      await saveScore();
    }
  }

  /// Efface la partition actuelle.
  Future<void> clearScore() async {
    _score = Score.defaultScore(measureCount: _score.measures.length);
    if (_scoreId != null && _metadata != null) {
      await saveScore();
    }
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
        newMeasures.add(Measure.defaultMeasure(newMeasures.length + 1));
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

    // Créer le NoteEvent
    final noteEvent = NoteEvent(
      actualDuration: eventDuration,
      writenDuration: selectedDuration,
      isRest: isRest,
      ornament: null,
      accent: null,
      isAboveLine: placeAboveLine,
    );

    // Insérer la note dans la mesure
    final updatedMeasure = MeasureEditor.insertNotes(measure, eventIndex, [
      noteEvent,
    ]);

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

    // Durée de chaque note du triolet (1/3 de la durée de base)
    final tripletNoteDuration = DurationFraction(
      baseDuration.numerator,
      baseDuration.denominator * 3,
    );

    // Information du tuplet (3 notes prennent la durée de 2 notes)
    final tupletInfo = const TupletInfo(3, 1);

    // Créer 3 notes du triolet (alternant droite/gauche)
    final tripletNotes = [
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        tuplet: tupletInfo,
        isRest: false,
        isAboveLine: true, // Droite
      ),
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        tuplet: tupletInfo,
        isRest: false,
        isAboveLine: false, // Gauche
      ),
      NoteEvent(
        actualDuration: tripletNoteDuration,
        writenDuration: writenDuration,
        tuplet: tupletInfo,
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
