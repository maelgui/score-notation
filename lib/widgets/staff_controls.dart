import 'package:flutter/material.dart';

import '../utils/music_symbols.dart';

/// Widget pour les contrôles de la portée (nombre de barres, mesures par ligne, etc.)
class StaffControls extends StatelessWidget {
  const StaffControls({
    super.key,
    required this.measureCount,
    required this.measuresPerLine,
    required this.selectedDuration,
    required this.onMeasureCountChanged,
    required this.onMeasuresPerLineChanged,
    required this.onDurationChanged,
  });

  final int measureCount;
  final int measuresPerLine;
  final NoteDuration? selectedDuration;
  final ValueChanged<int> onMeasureCountChanged;
  final ValueChanged<int> onMeasuresPerLineChanged;
  final ValueChanged<NoteDuration> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Contrôle du nombre de barres et mesures par ligne
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Nombre de barres:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: measureCount.toDouble(),
                      min: 1,
                      max: 16,
                      divisions: 15,
                      label: '$measureCount',
                      onChanged: (value) {
                        onMeasureCountChanged(value.round());
                      },
                    ),
                  ),
                  Text('$measureCount'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Mesures par ligne:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: measuresPerLine.toDouble(),
                      min: 1,
                      max: 16,
                      divisions: 15,
                      label: '$measuresPerLine',
                      onChanged: (value) {
                        onMeasuresPerLineChanged(value.round());
                      },
                    ),
                  ),
                  Text('$measuresPerLine'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
                      final isSelected = selectedDuration == duration;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(duration.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              onDurationChanged(duration);
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
      ],
    );
  }
}
