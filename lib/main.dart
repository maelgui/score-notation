import 'package:flutter/material.dart';
import 'package:snare_notation/model/note_event.dart';

import 'model/accent.dart';
import 'model/ornament.dart';
import 'model/score.dart';
import 'model/selection_state.dart';
import 'controllers/score_controller.dart';
import 'services/storage_service.dart';
import 'utils/bravura_metrics.dart';
import 'utils/measure_editor.dart';
import 'utils/music_symbols.dart';
import 'utils/selection_utils.dart';
import 'utils/duration_converter.dart';
import 'widgets/staff_view.dart';
import 'widgets/symbol_palette.dart';
import 'widgets/rudiment_icon.dart';

void main() {
  runApp(const SnareNotationApp());
}

class SnareNotationApp extends StatelessWidget {
  const SnareNotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snare Notation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StaffScreen(),
    );
  }
}

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

enum EditMode {
  write, // Mode écriture : ajouter des notes
  select, // Mode sélection : sélectionner des notes existantes
}

class _StaffScreenState extends State<StaffScreen> {
  static const int _defaultBarCount = 4;
  static const int _defaultMeasuresPerLine = 4;
  final StorageService _storageService = StorageService();
  late final ScoreController _scoreController;

  Score get _score => _scoreController.score;
  SelectedSymbol _selectedSymbol = SelectedSymbol.right;
  NoteDuration? _selectedDuration = NoteDuration.quarter;
  bool _isLoading = true;
  EditMode _editMode = EditMode.write;
  int _measuresPerLine = _defaultMeasuresPerLine;

  // Pour le mode sélection : stocker la note sélectionnée
  int? _selectedMeasureIndex;
  int? _selectedEventIndex;
  SelectionState _selectionState = SelectionState();

  static const List<PaletteSymbol<SelectedSymbol>> _availableSymbols = [
    PaletteSymbol(
      label: 'Droite',
      id: SelectedSymbol.right,
      symbol: MusicSymbols.quarterNote,
    ),
    PaletteSymbol(
      label: 'Gauche',
      id: SelectedSymbol.left,
      symbol: MusicSymbols.quarterNoteUp,
    ),
    PaletteSymbol(
      label: 'Silence',
      id: SelectedSymbol.rest,
      symbol: MusicSymbols.restQuarter,
    ),
  ];

  static final List<PaletteSymbol<ModificationSymbol>> _modificationSymbols = [
    const PaletteSymbol(
      label: 'Accent',
      id: ModificationSymbol.accent,
      symbol: MusicSymbols.accent,
    ),
    PaletteSymbol(
      label: 'Flam',
      id: ModificationSymbol.flam,
      symbol: MusicSymbols.flam,
      iconBuilder: (context, isActive) =>
          RudimentIcon(graceNoteCount: 1, isActive: isActive),
    ),
    PaletteSymbol(
      label: 'Drag',
      id: ModificationSymbol.drag,
      symbol: MusicSymbols.drag,
      iconBuilder: (context, isActive) =>
          RudimentIcon(graceNoteCount: 2, isActive: isActive),
    ),
    const PaletteSymbol(
      label: 'Roulement',
      id: ModificationSymbol.roll,
      symbol: MusicSymbols.roll,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur de manière synchrone
    _scoreController = ScoreController(
      storageService: _storageService,
      defaultBarCount: _defaultBarCount,
    );
    // Charger les métriques Bravura de manière asynchrone (ne bloque pas l'initialisation)
    _loadBravuraMetrics();
    _loadScore();
  }

  Future<void> _loadBravuraMetrics() async {
    // Charger les métriques Bravura en arrière-plan
    await BravuraMetrics.load();
    // Forcer un rebuild après le chargement pour utiliser les vraies valeurs SMuFL
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadScore() async {
    try {
      await _scoreController.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger la partition: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClear() async {
    try {
      await _scoreController.clearScore();
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Effacement impossible: $error')));
    }
  }

  void _handleBarCountChanged(int newCount) {
    if (newCount < 1) return;

    _scoreController.setMeasureCount(newCount);
    setState(() {});
    _scoreController.saveScore();
  }

  NoteEvent? get _selectedEvent {
    if (_selectedMeasureIndex == null || _selectedEventIndex == null) return null;
    if (_selectedMeasureIndex! >= _score.measures.length) return null;
    final measure = _score.measures[_selectedMeasureIndex!];
    if (_selectedEventIndex! >= measure.events.length) return null;
    return measure.events[_selectedEventIndex!];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snare Notation'),
        actions: [
          // Sélecteur de mode
          SegmentedButton<EditMode>(
            segments: const [
              ButtonSegment<EditMode>(
                value: EditMode.write,
                label: Text('Écriture'),
                icon: Icon(Icons.edit),
              ),
              ButtonSegment<EditMode>(
                value: EditMode.select,
                label: Text('Sélection'),
                icon: Icon(Icons.touch_app),
              ),
            ],
            selected: {_editMode},
            onSelectionChanged: (Set<EditMode> newSelection) {
              setState(() {
                _editMode = newSelection.first;
                // Réinitialiser la sélection quand on change de mode
                _selectedMeasureIndex = null;
                _selectedEventIndex = null;
                _selectionState = SelectionState();
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer',
            onPressed: _scoreController.hasNotes() ? _handleClear : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Contrôle du nombre de barres et mesures par ligne
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Nombre de barres:'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _score.measures.length.toDouble(),
                              min: 1,
                              max: 16,
                              divisions: 15,
                              label: '${_score.measures.length}',
                              onChanged: (value) {
                                _handleBarCountChanged(value.round());
                              },
                            ),
                          ),
                          Text('${_score.measures.length}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Mesures par ligne:'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _measuresPerLine.toDouble(),
                              min: 1,
                              max: 16,
                              divisions: 15,
                              label: '$_measuresPerLine',
                              onChanged: (value) {
                                setState(() {
                                  _measuresPerLine = value.round();
                                });
                              },
                            ),
                          ),
                          Text('$_measuresPerLine'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Vue de la portée
                Expanded(
                  child: StaffView(
                    score: _score,
                    editMode: _editMode,
                    cursorPosition: _selectionState.cursor,
                    selectedNotes: _selectionState.selectedNotes,
                    measuresPerLine: _measuresPerLine,
                    onBeatSelected: _editMode == EditMode.write
                        ? _handleAddNoteAtBeat
                        : _handleSelectNote,
                    onCursorChanged: _handleCursorChanged,
                    onSelectionDragStart: _handleSelectionDragStart,
                    onSelectionDragUpdate: _handleSelectionDragUpdate,
                    onSelectionDragEnd: _handleSelectionDragEnd,
                    onSelectionCleared: _handleSelectionCleared,
                  ),
                ),
                // Sélecteur de durée
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text('Durée:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: NoteDuration.values.map((duration) {
                              final isSelected = _selectedDuration == duration;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(duration.label),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedDuration = duration;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Palette unifiée de symboles (tous les symboles dans une même barre)
                _UnifiedPalette(
                  selectedSymbol: _selectedSymbol,
                  availableSymbols: _availableSymbols,
                  modificationSymbols: _modificationSymbols,
                  selectedEvent: _selectedEvent,
                  onSelectedSymbolSelected: (symbol) {
                    _handleSymbolSelected(symbol);
                  },
                  onModificationSymbolSelected: (symbol) {
                    _handleModifyNote(symbol);
                  },
                ),
              ],
            ),
    );
  }

  Future<void> _handleAddNoteAtBeat(
    int measureIndex,
    int eventIndex,
    bool placeAboveLine,
  ) async {
    await _scoreController.addNoteAtBeat(
      measureIndex,
      eventIndex: eventIndex,
      selectedSymbol: _selectedSymbol,
      selectedDuration: _selectedDuration,
    );
    if (!mounted) return;
    setState(() {});
  }

  /// Gère la sélection d'une note en mode sélection.
  Future<void> _handleSelectNote(
    int measureIndex,
    int eventIndex,
    bool placeAboveLine,
  ) async {
    if (measureIndex < 0 || measureIndex >= _score.measures.length) {
      return;
    }

    // Trouver la position de l'événement sélectionné
    final measure = _score.measures[measureIndex];
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(
      measure,
    );
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
      final NoteDuration? correspondingDuration = DurationConverter.fromFraction(selectedEvent.duration);
      
      setState(() {
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
      });
    }
  }

  void _handleCursorChanged(StaffCursorPosition cursor) {
    if (_editMode != EditMode.select) return;
    setState(() {
      _selectionState = _selectionState.copyWith(cursor: cursor);
    });
  }

  void _handleSelectionDragStart(StaffCursorPosition cursor) {
    if (_editMode != EditMode.select) return;
    setState(() {
      _selectedMeasureIndex = null;
      _selectedEventIndex = null;
      _selectionState = SelectionState(
        cursor: cursor,
        range: SelectionRange(start: cursor, end: cursor),
      );
    });
  }

  void _handleSelectionDragUpdate(StaffCursorPosition cursor) {
    if (_editMode != EditMode.select) return;
    final SelectionRange range = _selectionState.range == null
        ? SelectionRange(start: cursor, end: cursor)
        : SelectionRange(start: _selectionState.range!.start, end: cursor);
    final selectedNotes = SelectionUtils.notesWithinRange(_score, range);
    setState(() {
      _selectionState = SelectionState(
        cursor: cursor,
        range: range,
        selectedNotes: selectedNotes,
      );
    });
  }

  void _handleSelectionDragEnd() {
    if (_editMode != EditMode.select) return;
    final selected = _selectionState.selectedNotes;
    if (selected.length == 1) {
      final ref = selected.first;
      setState(() {
        _selectedMeasureIndex = ref.measureIndex;
        _selectedEventIndex = ref.eventIndex;
      });
    } else {
      setState(() {
        _selectedMeasureIndex = null;
        _selectedEventIndex = null;
      });
    }
  }

  void _handleSelectionCleared() {
    if (_editMode != EditMode.select) return;
    setState(() {
      _selectedMeasureIndex = null;
      _selectedEventIndex = null;
      _selectionState = _selectionState.copyWith(
        clearRange: true,
        clearSelectedNotes: true,
      );
    });
  }

  /// Gère la sélection d'un symbole dans la palette.
  /// Remplace la note sélectionnée
  Future<void> _handleSymbolSelected(SelectedSymbol symbol) async {
    setState(() {
      _selectedSymbol = symbol;
    });

    if (_selectedMeasureIndex == null || _selectedEventIndex == null) {
      return;
    }

    // Si une note est sélectionnée, la remplacer en gardant sa durée
    final measure = _score.measures[_selectedMeasureIndex!];
    if (_selectedEventIndex! >= 0 &&
        _selectedEventIndex! < measure.events.length) {
      await _scoreController.addNoteAtBeat(
        _selectedMeasureIndex!,
        eventIndex: _selectedEventIndex!,
        selectedSymbol: symbol,
        selectedDuration: _selectedDuration,
      );

      // Selection la note suivante
      _handleSelectNote(
        _selectedMeasureIndex!,
        _selectedEventIndex! + 1,
        false,
      );

      setState(() {});
      return;
    }
  }

  /// Gère la modification d'une note sélectionnée.
  Future<void> _handleModifyNote(String symbol) async {
    if (_selectedMeasureIndex == null || _selectedEventIndex == null) {
      return;
    }

    final measure = _score.measures[_selectedMeasureIndex!];
    final event = measure.events[_selectedEventIndex!];

    Accent? accent = event.accent; // Préserver l'accent existant
    Ornament? ornament = event.ornament; // Préserver l'ornement existant

    if (symbol == MusicSymbols.accent) {
      // Toggle accent
      accent = event.accent == Accent.accent ? null : Accent.accent;
    } else if (symbol == MusicSymbols.flam) {
      // Toggle flam (retirer si déjà flam, sinon mettre flam et retirer les autres ornements)
      ornament = event.ornament == Ornament.flam ? null : Ornament.flam;
    } else if (symbol == MusicSymbols.drag) {
      // Toggle drag (retirer si déjà drag, sinon mettre drag et retirer les autres ornements)
      ornament = event.ornament == Ornament.drag ? null : Ornament.drag;
    } else if (symbol == MusicSymbols.roll) {
      // Toggle roll (retirer si déjà roll, sinon mettre roll et retirer les autres ornements)
      ornament = event.ornament == Ornament.roll ? null : Ornament.roll;
    }

    await _scoreController.modifyNote(
      _selectedMeasureIndex!,
      _selectedEventIndex!,
      accent: accent,
      ornament: ornament,
    );
    if (!mounted) return;
    setState(() {});
  }
}

/// Bouton de palette unifié qui peut afficher une ligne de portée ou non.
class _UnifiedPaletteButton extends StatelessWidget {
  const _UnifiedPaletteButton({
    required this.option,
    required this.isActive,
    required this.showStaffLine,
    required this.onTap,
    this.isDisabled = false,
  });

  final PaletteSymbol option;
  final bool isActive;
  final bool showStaffLine;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color borderColor = isDisabled
        ? colorScheme.outline.withOpacity(0.3)
        : (isActive
            ? colorScheme.primary
            : colorScheme.outline);
    final Color backgroundColor = isDisabled
        ? colorScheme.surface.withOpacity(0.5)
        : (isActive
            ? colorScheme.primaryContainer
            : colorScheme.surface);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            option.iconBuilder?.call(context, isActive) ??
                (showStaffLine
                    ? SizedBox(
                        width: 64,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ligne de portée complètement dépassant le symbole
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 24,
                              height: 2,
                              child: Container(color: Colors.black),
                            ),
                            // Symbole de la note
                            Center(
                              child: Text(
                                option.symbol,
                                style: const TextStyle(
                                  fontFamily: 'Bravura',
                                  fontSize: 32,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        option.symbol,
                        style: TextStyle(
                          fontFamily: 'Bravura',
                          fontSize: 32,
                          color: isDisabled
                              ? Colors.grey
                              : (isActive ? colorScheme.primary : Colors.black),
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      )),
            const SizedBox(height: 4),
            Text(
              option.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDisabled
                    ? Colors.grey
                    : (isActive ? colorScheme.primary : null),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Palette unifiée qui affiche tous les symboles (SelectedSymbol et ModificationSymbol) dans une même barre.
class _UnifiedPalette extends StatelessWidget {
  const _UnifiedPalette({
    required this.selectedSymbol,
    required this.availableSymbols,
    required this.modificationSymbols,
    this.selectedEvent,
    required this.onSelectedSymbolSelected,
    required this.onModificationSymbolSelected,
  });

  final SelectedSymbol selectedSymbol;
  final List<PaletteSymbol<SelectedSymbol>> availableSymbols;
  final List<PaletteSymbol<ModificationSymbol>> modificationSymbols;
  final NoteEvent? selectedEvent;
  final ValueChanged<SelectedSymbol> onSelectedSymbolSelected;
  final ValueChanged<String> onModificationSymbolSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Vérifier si une note est sélectionnée
    final bool hasNoteSelected = selectedEvent != null;

    // Déterminer l'état actif des ModificationSymbols si une note est sélectionnée
    final bool hasAccent = selectedEvent?.accent == Accent.accent;
    final bool hasFlam = selectedEvent?.ornament == Ornament.flam;
    final bool hasDrag = selectedEvent?.ornament == Ornament.drag;
    final bool hasRoll = selectedEvent?.ornament == Ornament.roll;

    return Material(
      elevation: 4,
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              // Afficher d'abord les SelectedSymbols
              if (index < availableSymbols.length) {
                final PaletteSymbol<SelectedSymbol> option =
                    availableSymbols[index];
                final bool isSelected = option.id == selectedSymbol;
                return _UnifiedPaletteButton(
                  option: option,
                  isActive: isSelected,
                  showStaffLine: true,
                  onTap: () => onSelectedSymbolSelected(option.id),
                );
              }

              // Ensuite les ModificationSymbols
              final modificationIndex = index - availableSymbols.length;
              if (modificationIndex < modificationSymbols.length) {
                final PaletteSymbol<ModificationSymbol> option =
                    modificationSymbols[modificationIndex];
                final bool isActive;

                // Déterminer si cet attribut est actif
                if (option.symbol == MusicSymbols.accent) {
                  isActive = hasAccent;
                } else if (option.symbol == MusicSymbols.flam) {
                  isActive = hasFlam;
                } else if (option.symbol == MusicSymbols.drag) {
                  isActive = hasDrag;
                } else if (option.symbol == MusicSymbols.roll) {
                  isActive = hasRoll;
                } else {
                  isActive = false;
                }

                return _UnifiedPaletteButton(
                  option: option,
                  isActive: isActive,
                  showStaffLine: false,
                  isDisabled: !hasNoteSelected,
                  onTap: () => onModificationSymbolSelected(option.symbol),
                );
              }

              return const SizedBox.shrink();
            },
            separatorBuilder: (context, index) {
              // Ajouter un séparateur plus large entre les deux groupes de symboles
              // Le separatorBuilder reçoit l'index du séparateur (entre index et index+1)
              // Donc après le dernier SelectedSymbol (index = availableSymbols.length - 1)
              if (index == availableSymbols.length - 1) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 2,
                      height: 60,
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                  ],
                );
              }
              return const SizedBox(width: 12);
            },
            itemCount: availableSymbols.length + modificationSymbols.length,
          ),
        ),
      ),
    );
  }
}

// FUTURE EXTENSIONS:
// - Ajouter des gestes avancés (glisser-déposer, sélection multiple, undo/redo).
// - Export PNG/PDF du canvas (voir CustomPainter.toImage et packages comme printing).
// - Playback MIDI ou synthèse audio pour pré-écouter la séquence.
// - Édition de la signature rythmique par barre.
