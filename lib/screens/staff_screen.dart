import 'package:flutter/material.dart';

import '../controllers/staff_screen_controller.dart';
import '../services/storage_service.dart';
import '../utils/bravura_metrics.dart';
import '../utils/music_symbols.dart';
import '../widgets/staff_controls.dart';
import '../widgets/staff_view.dart';
import '../widgets/unified_palette.dart';

/// Écran d'édition de partition qui charge une partition spécifique par ID.
class StaffScreen extends StatefulWidget {
  final String scoreId;

  const StaffScreen({super.key, required this.scoreId});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late final StaffScreenController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = StaffScreenController(
      storageService: StorageService(),
    );
    // Charger la partition spécifique
    _controller.scoreController.loadScore(widget.scoreId);
    _loadBravuraMetrics();
    _controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Impossible de charger la partition: $error'),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBravuraMetrics() async {
    await BravuraMetrics.load();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _controller.scoreController.metadata?.title ?? 'Partition';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // La partition a potentiellement été modifiée
          // Le retour sera géré automatiquement par la navigation
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Effacer',
              onPressed: _controller.scoreController.hasNotes()
                  ? () async {
                      try {
                        await _controller.clearScore();
                        setState(() {});
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Effacement impossible: $error'),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _StaffScreenContent(controller: _controller),
      ),
    );
  }
}

/// Widget qui affiche le contenu de l'éditeur de partition.
class _StaffScreenContent extends StatefulWidget {
  final StaffScreenController controller;

  const _StaffScreenContent({required this.controller});

  @override
  State<_StaffScreenContent> createState() => _StaffScreenContentState();
}

class _StaffScreenContentState extends State<_StaffScreenContent> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Column(
          children: [
            // Vue de la portée
            Expanded(
              child: StaffView(
                score: widget.controller.score,
                cursorPosition: widget.controller.selectionState.cursor,
                selectedNotes: widget.controller.selectionState.selectedNotes,
                measuresPerLine: widget.controller.score.measuresPerLine,
                onBeatSelected: widget.controller.selectNote,
                onCursorChanged: widget.controller.handleCursorChanged,
                onSelectionDragStart:
                    widget.controller.handleSelectionDragStart,
                onSelectionDragUpdate:
                    widget.controller.handleSelectionDragUpdate,
                onSelectionDragEnd: widget.controller.handleSelectionDragEnd,
                onSelectionCleared: widget.controller.clearSelection,
              ),
            ),
            const Divider(height: 1),
            // Contrôles de la portée (durée, nombre de mesures, etc.)
            DurationControls(
              selectedDuration:
                  widget.controller.selectedDuration ?? NoteDuration.quarter,
              onDurationChanged: widget.controller.setSelectedDuration,
            ),
            const Divider(height: 1),
            // Palette unifiée de symboles
            UnifiedPalette(
              selectedSymbol: widget.controller.selectedSymbol,
              availableSymbols: PaletteSymbols.availableSymbols,
              modificationSymbols: PaletteSymbols.modificationSymbols,
              selectedEvent: widget.controller.selectedEvent,
              onSelectedSymbolSelected: widget.controller.replaceSelectedNote,
              onModificationSymbolSelected: widget.controller.modifySelectedNote,
            ),
          ],
        );
      },
    );
  }
}
