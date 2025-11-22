import 'package:flutter/foundation.dart';

import '../model/accent.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../model/score.dart';
import '../model/selection_state.dart';
import '../services/storage_service.dart';
import '../utils/duration_converter.dart';
import '../utils/measure_editor.dart';
import '../utils/music_symbols.dart';
import '../widgets/unified_palette.dart';
import 'score_with_metadata_controller.dart';

/// Contrôleur pour gérer l'état et la logique de l'écran principal de la portée.
/// Sépare la logique métier de l'interface utilisateur.
class StaffScreenController extends ChangeNotifier {
  StaffScreenController({
    required StorageService storageService,
    int defaultBarCount = 4,
    int defaultMeasuresPerLine = 4,
  }) : _defaultMeasuresPerLine = defaultMeasuresPerLine {
    _scoreController = ScoreWithMetadataController(
      storageService: storageService,
      defaultBarCount: defaultBarCount,
    );
  }

  final int _defaultMeasuresPerLine;
  late final ScoreWithMetadataController _scoreController;

  // État de l'interface
  bool _isLoading = true;

  // État de sélection
  SelectedSymbol _selectedSymbol = SelectedSymbol.right;
  NoteDuration? _selectedDuration = NoteDuration.quarter;
  int? _selectedMeasureIndex;
  int? _selectedEventIndex;
  SelectionState _selectionState = SelectionState();

  // Getters
  bool get isLoading => _isLoading;
  int get measuresPerLine => _scoreController.score.measuresPerLine;
  SelectedSymbol get selectedSymbol => _selectedSymbol;
  NoteDuration? get selectedDuration => _selectedDuration;
  int? get selectedMeasureIndex => _selectedMeasureIndex;
  int? get selectedEventIndex => _selectedEventIndex;
  SelectionState get selectionState => _selectionState;
  Score get score => _scoreController.score;
  ScoreWithMetadataController get scoreController => _scoreController;

  /// Indique si une note est actuellement sélectionnée
  bool get hasSelection => _selectedMeasureIndex != null && _selectedEventIndex != null;

  NoteEvent? get selectedEvent {
    if (_selectedMeasureIndex == null || _selectedEventIndex == null) return null;
    if (_selectedMeasureIndex! >= score.measures.length) return null;
    final measure = score.measures[_selectedMeasureIndex!];
    if (_selectedEventIndex! >= measure.events.length) return null;
    return measure.events[_selectedEventIndex!];
  }

  /// Initialise le contrôleur
  Future<void> initialize() async {
    try {
      await _scoreController.initialize();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }



  /// Change le symbole sélectionné
  void setSelectedSymbol(SelectedSymbol symbol) {
    if (_selectedSymbol != symbol) {
      _selectedSymbol = symbol;
      notifyListeners();
    }
  }

  /// Change la durée sélectionnée
  void setSelectedDuration(NoteDuration duration) {
    if (_selectedDuration != duration) {
      _selectedDuration = duration;
      notifyListeners();
    }
  }

  /// Efface la partition
  Future<void> clearScore() async {
    try {
      await _scoreController.clearScore();
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }


  /// Ajoute une note à une position donnée
  Future<void> addNoteAtBeat(
    int measureIndex,
    int eventIndex,
    bool placeAboveLine,
  ) async {
    if (_selectedDuration == null) return;

    await _scoreController.addNoteAtBeat(
      measureIndex,
      eventIndex: eventIndex,
      selectedSymbol: _selectedSymbol,
      selectedDuration: _selectedDuration!,
    );

    // Sélectionner automatiquement la note/silence suivant
    await _selectNextEvent(measureIndex, eventIndex);

    notifyListeners();
  }

  /// Sélectionne une note
  Future<void> selectNote(
    int measureIndex,
    int eventIndex,
    bool placeAboveLine,
  ) async {
    if (measureIndex < 0 || measureIndex >= score.measures.length) {
      return;
    }

    // Trouver la position de l'événement sélectionné
    final measure = score.measures[measureIndex];
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);

    if (eventIndex >= 0 && eventIndex < eventsWithPositions.length) {
      final entry = eventsWithPositions[eventIndex];
      final cursor = StaffCursorPosition(
        measureIndex: measureIndex,
        eventIndex: eventIndex,
        isAfterEvent: false,
        positionInMeasure: entry.position,
      );
      final selectionRef = NoteSelectionReference(
        measureIndex: measureIndex,
        eventIndex: eventIndex,
      );

      // Mettre à jour la durée sélectionnée avec celle de la note
      final selectedEvent = measure.events[eventIndex];
      final NoteDuration? correspondingDuration = DurationConverter.fromFraction(selectedEvent.actualDuration);

      _selectedMeasureIndex = measureIndex;
      _selectedEventIndex = eventIndex;
      if (correspondingDuration != null) {
        _selectedDuration = correspondingDuration;
      }
      _selectionState = SelectionState(
        cursor: cursor,
        range: SelectionRange(start: cursor, end: cursor),
        selectedNotes: {selectionRef},
      );
      notifyListeners();
    }
  }

  /// Modifie une note sélectionnée avec un symbole
  Future<void> modifySelectedNote(String symbol) async {
    if (_selectedMeasureIndex == null || _selectedEventIndex == null) {
      return;
    }

    final measure = score.measures[_selectedMeasureIndex!];
    final event = measure.events[_selectedEventIndex!];

    Accent? accent = event.accent;
    Ornament? ornament = event.ornament;

    if (symbol == MusicSymbols.accent) {
      accent = event.accent == Accent.accent ? null : Accent.accent;
    } else if (symbol == MusicSymbols.flam) {
      ornament = event.ornament == Ornament.flam ? null : Ornament.flam;
    } else if (symbol == MusicSymbols.drag) {
      ornament = event.ornament == Ornament.drag ? null : Ornament.drag;
    } else if (symbol == MusicSymbols.roll) {
      ornament = event.ornament == Ornament.roll ? null : Ornament.roll;
    }

    await _scoreController.modifyNote(
      _selectedMeasureIndex!,
      _selectedEventIndex!,
      accent: accent,
      ornament: ornament,
    );
    notifyListeners();
  }

  /// Remplace la note sélectionnée par un nouveau symbole
  Future<void> replaceSelectedNote(SelectedSymbol symbol) async {
    if (_selectedDuration == null) return;

    setSelectedSymbol(symbol);

    if (_selectedMeasureIndex == null || _selectedEventIndex == null) {
      return;
    }

    // Remplacer la note en gardant sa durée
    final measure = score.measures[_selectedMeasureIndex!];
    if (_selectedEventIndex! >= 0 && _selectedEventIndex! < measure.events.length) {
      await _scoreController.addNoteAtBeat(
        _selectedMeasureIndex!,
        eventIndex: _selectedEventIndex!,
        selectedSymbol: symbol,
        selectedDuration: _selectedDuration!,
      );

      // Sélectionner automatiquement la note/silence suivant
      await _selectNextEvent(_selectedMeasureIndex!, _selectedEventIndex!);
      notifyListeners();
    }
  }

  /// Gère les changements de curseur
  void handleCursorChanged(StaffCursorPosition cursor) {
    _selectionState = _selectionState.copyWith(cursor: cursor);
    notifyListeners();
  }

  /// Gère le début de sélection par glissement
  void handleSelectionDragStart(StaffCursorPosition cursor) {
    _selectedMeasureIndex = null;
    _selectedEventIndex = null;
    _selectionState = SelectionState(
      cursor: cursor,
      range: SelectionRange(start: cursor, end: cursor),
    );
    notifyListeners();
  }

  /// Gère la mise à jour de sélection par glissement
  void handleSelectionDragUpdate(StaffCursorPosition cursor) {
    final SelectionRange range = _selectionState.range == null
        ? SelectionRange(start: cursor, end: cursor)
        : SelectionRange(start: _selectionState.range!.start, end: cursor);
    // Note: SelectionUtils.notesWithinRange nécessiterait d'être importé
    // Pour l'instant, on garde une sélection simple
    _selectionState = SelectionState(
      cursor: cursor,
      range: range,
      selectedNotes: <NoteSelectionReference>{},
    );
    notifyListeners();
  }

  /// Gère la fin de sélection par glissement
  void handleSelectionDragEnd() {
    final selected = _selectionState.selectedNotes;
    if (selected.length == 1) {
      final ref = selected.first;
      _selectedMeasureIndex = ref.measureIndex;
      _selectedEventIndex = ref.eventIndex;
    } else {
      _selectedMeasureIndex = null;
      _selectedEventIndex = null;
    }
    notifyListeners();
  }

  /// Efface la sélection
  void clearSelection() {
    _selectedMeasureIndex = null;
    _selectedEventIndex = null;
    _selectionState = _selectionState.copyWith(
      clearRange: true,
      clearSelectedNotes: true,
    );
    notifyListeners();
  }

  /// Sélectionne automatiquement la note/silence suivant après l'ajout d'une note
  Future<void> _selectNextEvent(int measureIndex, int eventIndex) async {
    // Calculer la position du prochain événement
    int nextMeasureIndex = measureIndex;
    int nextEventIndex = eventIndex + 1;

    // Vérifier si on dépasse la mesure actuelle
    if (nextEventIndex >= score.measures[measureIndex].events.length) {
      // Passer à la mesure suivante
      nextMeasureIndex++;
      nextEventIndex = 0;

      // Vérifier si on dépasse la partition
      if (nextMeasureIndex >= score.measures.length) {
        // Rester sur le dernier événement de la dernière mesure
        nextMeasureIndex = score.measures.length - 1;
        nextEventIndex = score.measures[nextMeasureIndex].events.length - 1;

        // Si la dernière mesure est vide, ne pas sélectionner
        if (nextEventIndex < 0) {
          clearSelection();
          return;
        }
      }
    }

    // Sélectionner le prochain événement
    await selectNote(nextMeasureIndex, nextEventIndex, false);
  }

}
