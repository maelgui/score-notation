import 'package:flutter/material.dart';

import 'model/accent.dart';
import 'model/duration_fraction.dart';
import 'model/ornament.dart';
import 'model/score.dart';
import 'controllers/score_controller.dart';
import 'services/storage_service.dart';
import 'utils/bravura_metrics.dart';
import 'utils/measure_editor.dart';
import 'utils/music_symbols.dart';
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
  final StorageService _storageService = StorageService();
  late final ScoreController _scoreController;

  Score get _score => _scoreController.score;
  String _selectedSymbol = MusicSymbols.quarterNote;
  NoteDuration? _selectedDuration = NoteDuration.quarter;
  bool _isLoading = true;
  EditMode _editMode = EditMode.write;
  
  // Pour le mode sélection : stocker la note sélectionnée
  int? _selectedMeasureIndex;
  DurationFraction? _selectedPosition;
  int? _selectedEventIndex;

  static const List<PaletteSymbol> _availableSymbols = [
    PaletteSymbol(label: 'Note', symbol: MusicSymbols.quarterNote),
    PaletteSymbol(label: 'Silence', symbol: MusicSymbols.restQuarter),
  ];

  static final List<PaletteSymbol> _modificationSymbols = [
    const PaletteSymbol(label: 'Accent', symbol: MusicSymbols.accent),
    PaletteSymbol(
      label: 'Flam',
      symbol: MusicSymbols.flam,
      iconBuilder: (context, isActive) => RudimentIcon(
        graceNoteCount: 1,
        isActive: isActive,
      ),
    ),
    PaletteSymbol(
      label: 'Drag',
      symbol: MusicSymbols.drag,
      iconBuilder: (context, isActive) => RudimentIcon(
        graceNoteCount: 2,
        isActive: isActive,
      ),
    ),
    const PaletteSymbol(label: 'Roulement', symbol: MusicSymbols.roll),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Effacement impossible: $error')),
      );
    }
  }

  void _handleBarCountChanged(int newCount) {
    if (newCount < 1) return;

    _scoreController.setMeasureCount(newCount);
    setState(() {});
    _scoreController.saveScore();
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
                _selectedPosition = null;
                _selectedEventIndex = null;
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer',
            onPressed: _scoreController.hasNotes()
                ? _handleClear
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Contrôle du nombre de barres
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
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
                ),
                const Divider(height: 1),
                // Vue de la portée
                Expanded(
                  child: StaffView(
                    score: _score,
                    editMode: _editMode,
                    selectedMeasureIndex: _selectedMeasureIndex,
                    selectedPosition: _selectedPosition,
                    onBeatSelected: _editMode == EditMode.write
                        ? _handleAddNoteAtBeat
                        : _handleSelectNote,
                  ),
                ),
                // Sélecteur de durée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                // Palette contextuelle de modification (mode sélection avec note sélectionnée)
                if (_editMode == EditMode.select && 
                    _selectedMeasureIndex != null && 
                    _selectedEventIndex != null)
                  Column(
                    children: [
                      _ModificationPalette(
                        symbols: _modificationSymbols,
                        selectedMeasureIndex: _selectedMeasureIndex!,
                        selectedEventIndex: _selectedEventIndex!,
                        score: _score,
                        onSymbolSelected: (symbol) {
                          _handleModifyNote(symbol);
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                // Palette de symboles (mode écriture ou sélection sans note sélectionnée)
                SymbolPalette(
                  symbols: _availableSymbols,
                  selectedSymbol: _selectedSymbol,
                  onSymbolSelected: (symbol) {
                    setState(() {
                      _selectedSymbol = symbol;
                    });
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
      placeAboveLine: placeAboveLine,
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
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);
    if (eventIndex >= 0 && eventIndex < eventsWithPositions.length) {
      final event = eventsWithPositions[eventIndex].event;
      // Ne sélectionner que les notes (pas les silences)
      if (!event.isRest) {
        setState(() {
          _selectedMeasureIndex = measureIndex;
          _selectedPosition = eventsWithPositions[eventIndex].position;
          _selectedEventIndex = eventIndex;
        });
    } else {
        // Désélectionner si on clique sur un silence
        setState(() {
          _selectedMeasureIndex = null;
          _selectedPosition = null;
          _selectedEventIndex = null;
        });
      }
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

/// Palette contextuelle pour modifier une note sélectionnée.
/// Affiche visuellement les attributs actifs de la note.
class _ModificationPalette extends StatelessWidget {
  const _ModificationPalette({
    required this.symbols,
    required this.selectedMeasureIndex,
    required this.selectedEventIndex,
    required this.score,
    required this.onSymbolSelected,
  });

  final List<PaletteSymbol> symbols;
  final int selectedMeasureIndex;
  final int selectedEventIndex;
  final Score score;
  final ValueChanged<String> onSymbolSelected;

  @override
  Widget build(BuildContext context) {
    // Récupérer la note sélectionnée
    if (selectedMeasureIndex < 0 || 
        selectedMeasureIndex >= score.measures.length) {
      return const SizedBox.shrink();
    }

    final measure = score.measures[selectedMeasureIndex];
    if (selectedEventIndex < 0 || selectedEventIndex >= measure.events.length) {
      return const SizedBox.shrink();
    }

    final event = measure.events[selectedEventIndex];
    
    // Déterminer quels attributs sont actifs
    final bool hasAccent = event.accent == Accent.accent;
    final bool hasFlam = event.ornament == Ornament.flam;
    final bool hasDrag = event.ornament == Ornament.drag;
    final bool hasRoll = event.ornament == Ornament.roll;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
              final PaletteSymbol option = symbols[index];
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

              return _ModificationPaletteButton(
                option: option,
                isActive: isActive,
                onTap: () => onSymbolSelected(option.symbol),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: symbols.length,
          ),
        ),
      ),
    );
  }
}

class _ModificationPaletteButton extends StatelessWidget {
  const _ModificationPaletteButton({
    required this.option,
    required this.isActive,
    required this.onTap,
  });

  final PaletteSymbol option;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color borderColor =
        isActive ? colorScheme.primary : colorScheme.outline;
    final Color backgroundColor =
        isActive ? colorScheme.primaryContainer : colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
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
                Text(
                  option.symbol,
                  style: TextStyle(
                    fontFamily: 'Bravura',
                    fontSize: 32,
                    color: isActive ? colorScheme.primary : Colors.black,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            const SizedBox(height: 4),
            Text(
              option.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isActive ? colorScheme.primary : null,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
