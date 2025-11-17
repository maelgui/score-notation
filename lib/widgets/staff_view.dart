import 'package:flutter/material.dart';

import '../model/score.dart';
import '../model/selection_state.dart';
import '../painters/staff_painter.dart';
import '../utils/constants.dart';
import '../utils/measure_editor.dart';
import '../utils/measure_helper.dart';
import '../utils/selection_utils.dart';
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
    this.cursorPosition,
    this.selectedNotes = const {},
    required this.onBeatSelected,
    this.onCursorChanged,
    this.onSelectionDragStart,
    this.onSelectionDragUpdate,
    this.onSelectionDragEnd,
    this.onSelectionCleared,
  });

  final Score score;
  final EditMode editMode;
  final StaffCursorPosition? cursorPosition;
  final Set<NoteSelectionReference> selectedNotes;
  final Future<void> Function(int measureIndex, int eventIndex, bool placeAboveLine)
      onBeatSelected;
  final void Function(StaffCursorPosition cursor)? onCursorChanged;
  final void Function(StaffCursorPosition cursor)? onSelectionDragStart;
  final void Function(StaffCursorPosition cursor)? onSelectionDragUpdate;
  final VoidCallback? onSelectionDragEnd;
  final VoidCallback? onSelectionCleared;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        StaffCursorPosition? resolveCursor(Offset position) {
          return SelectionUtils.cursorFromOffset(
            score: score,
            maxWidth: constraints.maxWidth,
            localPosition: position,
          );
        }

        ({int measureIndex, int eventIndex, bool placeAboveLine})?
            resolveTapTarget(TapDownDetails details) {
          if (score.measures.isEmpty) return null;

            final double padding = StaffPainter.defaultPadding;
            final double availableWidth = constraints.maxWidth - 2 * padding;
          final double rawMeasureWidth =
              score.measures.length == 0 ? availableWidth : availableWidth / score.measures.length;
          final double measureWidth = rawMeasureWidth <= 0 ? 1.0 : rawMeasureWidth;
            final double centerY = constraints.maxHeight / 2;

            final double localDx = details.localPosition.dx;
            final double localDy = details.localPosition.dy;
            final double relativeX = localDx - padding;

            int measureIndex = (relativeX / measureWidth).floor();
            measureIndex = measureIndex.clamp(0, score.measures.length - 1);

            final measure = score.measures[measureIndex];
            final double measureStartX = measureIndex * measureWidth;
            final double notesStartX = AppConstants.spaceBeforeBarline;
          final double notesEndX =
              measureWidth - AppConstants.barSpacing - AppConstants.spaceBeforeBarline;
            final double notesSpan = notesEndX - notesStartX;

            final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);
            final double symbolSize = AppConstants.symbolFontSize;
          final double hitRadius =
              symbolSize * AppConstants.hitRadiusMultiplier + AppConstants.hitRadiusPadding;
            
            final maxDuration = measure.maxDuration;
            final double maxDurationValue = MeasureHelper.fractionToPosition(maxDuration);
            
            int? closestEntryIndex;
            double minDistance = double.infinity;
            
            for (int i = 0; i < eventsWithPositions.length; i++) {
              final entry = eventsWithPositions[i];
              final positionValue = MeasureHelper.fractionToPosition(entry.position);
            final double normalizedEventPosition =
                maxDurationValue > 0 ? (positionValue / maxDurationValue).clamp(0.0, 1.0) : 0.0;
            final double symbolX = padding +
                measureStartX +
                notesStartX +
                normalizedEventPosition * notesSpan;
              
              final double distanceX = (localDx - symbolX).abs();
              final double distanceY = (localDy - centerY).abs();
              final double totalDistance = (distanceX * distanceX + distanceY * distanceY);
              
              if (distanceX < hitRadius && distanceY < hitRadius) {
                if (totalDistance < minDistance) {
                  minDistance = totalDistance;
                  closestEntryIndex = i;
                }
              }
            }
            
          if (closestEntryIndex == null) return null;
              final bool placeAboveLine = localDy <= centerY;
          return (
            measureIndex: measureIndex,
            eventIndex: closestEntryIndex,
            placeAboveLine: placeAboveLine,
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final cursor = resolveCursor(details.localPosition);
            if (cursor != null) {
              onCursorChanged?.call(cursor);
            }

            final hit = resolveTapTarget(details);
            if (editMode == EditMode.write) {
              if (hit != null) {
                onBeatSelected(hit.measureIndex, hit.eventIndex, hit.placeAboveLine);
              }
            } else {
              if (hit != null) {
                onBeatSelected(hit.measureIndex, hit.eventIndex, hit.placeAboveLine);
              } else {
                onSelectionCleared?.call();
              }
            }
          },
          onPanStart: editMode == EditMode.select
              ? (details) {
                  final cursor = resolveCursor(details.localPosition);
                  if (cursor == null) return;
                  onCursorChanged?.call(cursor);
                  onSelectionDragStart?.call(cursor);
                }
              : null,
          onPanUpdate: editMode == EditMode.select
              ? (details) {
                  final cursor = resolveCursor(details.localPosition);
                  if (cursor == null) return;
                  onCursorChanged?.call(cursor);
                  onSelectionDragUpdate?.call(cursor);
                }
              : null,
          onPanEnd: editMode == EditMode.select
              ? (_) {
                  onSelectionDragEnd?.call();
                }
              : null,
          onPanCancel: editMode == EditMode.select
              ? () {
                  onSelectionDragEnd?.call();
                }
              : null,
          child: CustomPaint(
            painter: StaffPainter(
              score: score,
              cursorPosition: cursorPosition,
              selectedNotes: selectedNotes,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
