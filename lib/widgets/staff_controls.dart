import 'package:flutter/material.dart';

import '../utils/music_symbols.dart';

/// Widget pour les contrôles de la portée (nombre de barres, mesures par ligne, etc.)
class DurationControls extends StatelessWidget {
  const DurationControls({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  final NoteDuration? selectedDuration;
  final ValueChanged<NoteDuration> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
