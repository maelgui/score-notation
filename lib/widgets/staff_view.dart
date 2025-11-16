import 'package:flutter/material.dart';

import '../model/score.dart';
import '../model/duration_fraction.dart';
import '../painters/staff_painter.dart';
import '../utils/constants.dart';
import '../utils/measure_editor.dart';
import '../utils/measure_helper.dart';
import '../main.dart';

/// Widget principal pour la zone de dessin de la portée.
///
/// Il capture les taps/clics et calcule la mesure et le temps ciblés,
/// puis prévient le parent via [onBeatSelected].
class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    required this.score,
    required this.editMode,
    this.selectedMeasureIndex,
    this.selectedPosition,
    required this.onBeatSelected,
  });

  final Score score;
  final EditMode editMode;
  final int? selectedMeasureIndex;
  final DurationFraction? selectedPosition;
  final Future<void> Function(int measureIndex, int eventIndex) onBeatSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (score.measures.isEmpty) return;

            final double padding = StaffPainter.defaultPadding;
            final double availableWidth = constraints.maxWidth - 2 * padding;
            final double measureWidth = availableWidth / score.measures.length;
            final double centerY = constraints.maxHeight / 2;

            final double localDx = details.localPosition.dx;
            final double localDy = details.localPosition.dy;
            final double relativeX = localDx - padding;

            // Déterminer dans quelle mesure on a cliqué
            int measureIndex = (relativeX / measureWidth).floor();
            measureIndex = measureIndex.clamp(0, score.measures.length - 1);

            final measure = score.measures[measureIndex];
            final double measureStartX = measureIndex * measureWidth;
            // Zone disponible pour les notes (avec padding interne)
            final double notesStartX = AppConstants.spaceBeforeBarline;
            final double notesEndX = measureWidth - AppConstants.barSpacing - AppConstants.spaceBeforeBarline;
            final double notesSpan = notesEndX - notesStartX;

            // Détecter si on a cliqué directement sur un symbole
            final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);
            final double symbolSize = AppConstants.symbolFontSize;
            final double hitRadius = symbolSize * AppConstants.hitRadiusMultiplier + AppConstants.hitRadiusPadding;
            
            // Calculer la position temporelle (en noires) dans cette mesure pour positionner les symboles
            final maxDuration = measure.maxDuration;
            final double maxDurationValue = MeasureHelper.fractionToPosition(maxDuration);
            
            // Trouver le symbole le plus proche du clic
            int? closestEntryIndex;
            double minDistance = double.infinity;
            
            for (int i = 0; i < eventsWithPositions.length; i++) {
              final entry = eventsWithPositions[i];
              final positionValue = MeasureHelper.fractionToPosition(entry.position);
              final double normalizedEventPosition = maxDurationValue > 0
                  ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
                  : 0.0;
              final double symbolX = padding + measureStartX + notesStartX + normalizedEventPosition * notesSpan;
              
              final double distanceX = (localDx - symbolX).abs();
              final double distanceY = (localDy - centerY).abs();
              final double totalDistance = (distanceX * distanceX + distanceY * distanceY);
              
              // Vérifier si on est dans le rayon de détection
              if (distanceX < hitRadius && distanceY < hitRadius) {
                if (totalDistance < minDistance) {
                  minDistance = totalDistance;
                  closestEntryIndex = i;
                }
              }
            }
            
            // Si on a trouvé un symbole proche, utiliser son index
            if (closestEntryIndex != null) {
              onBeatSelected(measureIndex, closestEntryIndex);
            }
          },
          child: CustomPaint(
            painter: StaffPainter(
              score: score,
              selectedMeasureIndex: selectedMeasureIndex,
              selectedPosition: selectedPosition,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
