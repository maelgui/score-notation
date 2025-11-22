import 'package:flutter/material.dart';
import 'package:snare_notation/widgets/symbol_palette.dart';

import 'controllers/staff_screen_controller.dart';
import 'services/storage_service.dart';
import 'utils/bravura_metrics.dart';
import 'utils/music_symbols.dart';
import 'widgets/rudiment_icon.dart';
import 'widgets/staff_controls.dart';
import 'widgets/staff_view.dart';
import 'widgets/unified_palette.dart';

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

class _StaffScreenState extends State<StaffScreen> {
  static const int _defaultBarCount = 4;
  static const int _defaultMeasuresPerLine = 4;
  late final StaffScreenController _controller;

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
    PaletteSymbol(
      label: 'Triolet',
      id: SelectedSymbol.triplet,
      symbol: '3', // Chiffre 3 pour représenter le triolet
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
    _controller = StaffScreenController(
      storageService: StorageService(),
      defaultBarCount: _defaultBarCount,
      defaultMeasuresPerLine: _defaultMeasuresPerLine,
    );
    _controller.addListener(_onControllerChanged);
    _loadBravuraMetrics();
    _controller.initialize().catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger la partition: $error')),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadBravuraMetrics() async {
    await BravuraMetrics.load();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleClear() async {
    try {
      await _controller.clearScore();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Effacement impossible: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snare Notation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer',
            onPressed: _controller.scoreController.hasNotes()
                ? _handleClear
                : null,
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Contrôles de la portée
                StaffControls(
                  measureCount: _controller.score.measures.length,
                  measuresPerLine: _controller.measuresPerLine,
                  selectedDuration: _controller.selectedDuration,
                  onMeasureCountChanged: _controller.setBarCount,
                  onMeasuresPerLineChanged: _controller.setMeasuresPerLine,
                  onDurationChanged: _controller.setSelectedDuration,
                ),
                const Divider(height: 1),
                // Vue de la portée
                Expanded(
                  child: StaffView(
                    score: _controller.score,
                    cursorPosition: _controller.selectionState.cursor,
                    selectedNotes: _controller.selectionState.selectedNotes,
                    measuresPerLine: _controller.measuresPerLine,
                    onBeatSelected: _controller.selectNote,
                    onCursorChanged: _controller.handleCursorChanged,
                    onSelectionDragStart: _controller.handleSelectionDragStart,
                    onSelectionDragUpdate:
                        _controller.handleSelectionDragUpdate,
                    onSelectionDragEnd: _controller.handleSelectionDragEnd,
                    onSelectionCleared: _controller.clearSelection,
                  ),
                ),
                const Divider(height: 1),
                // Palette unifiée de symboles
                UnifiedPalette(
                  selectedSymbol: _controller.selectedSymbol,
                  availableSymbols: _availableSymbols,
                  modificationSymbols: _modificationSymbols,
                  selectedEvent: _controller.selectedEvent,
                  onSelectedSymbolSelected: _controller.replaceSelectedNote,
                  onModificationSymbolSelected: _controller.modifySelectedNote,
                ),
              ],
            ),
    );
  }
}

// FUTURE EXTENSIONS:
// - Ajouter des gestes avancés (glisser-déposer, sélection multiple, undo/redo).
// - Export PNG/PDF du canvas (voir CustomPainter.toImage et packages comme printing).
// - Playback MIDI ou synthèse audio pour pré-écouter la séquence.
// - Édition de la signature rythmique par barre.
