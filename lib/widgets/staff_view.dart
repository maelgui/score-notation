import 'package:flutter/material.dart';

import '../model/duration_fraction.dart';
import '../model/score.dart';
import '../model/selection_state.dart';
import '../services/layout_engine/page_engine.dart';
import '../services/render_engine/staff_painter.dart';
import '../utils/constants.dart';
import '../utils/measure_editor.dart';
import '../utils/smufl/engraving_defaults.dart';
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
    this.measuresPerLine = 4,
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
  final int measuresPerLine;
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
        // Calculer le layout une seule fois et le réutiliser
        final double padding = AppConstants.staffPadding;
        final double availableWidth = constraints.maxWidth - 2 * padding;
        final double referenceStaffY = constraints.maxHeight / 2;

        final pageLayoutResult = PageEngine.layoutPage(
          score: score,
          measuresPerLine: measuresPerLine,
          availableWidth: availableWidth,
          padding: padding,
          referenceStaffY: referenceStaffY,
          sizeHeight: constraints.maxHeight,
        );

        StaffCursorPosition? resolveCursor(Offset position) {
          // Trouver la mesure qui contient cette position
          for (final system in pageLayoutResult.systems) {
            for (final measureLayout in system.measures) {
              if (measureLayout.boundingBox.contains(position)) {
                // Trouver l'index de la mesure dans le score
                final measureIndex = score.measures.indexOf(measureLayout.measureModel);
                if (measureIndex < 0) continue;

                // Calculer la position normalisée dans la mesure
                final double relativeX = position.dx - measureLayout.barlineXStart;
                final double notesStartX = measureLayout.barlineXStart + EngravingDefaults.spaceBeforeBarline;
                final double notesEndX = measureLayout.barlineXEnd - EngravingDefaults.spaceBeforeBarline;
                final double notesSpan = notesEndX - notesStartX;
                
                if (notesSpan <= 0) continue;

                final double normalized = ((relativeX - EngravingDefaults.spaceBeforeBarline) / notesSpan).clamp(0.0, 1.0);
                final measure = measureLayout.measureModel;
                
                // Convertir la position normalisée en DurationFraction
                final clamped = normalized.clamp(0.0, 1.0);
                final int cursorPrecision = 2048;
                final normalizedFraction = DurationFraction(
                  (clamped * cursorPrecision).round(),
                  cursorPrecision,
                );
                final DurationFraction positionInMeasure = measure.maxDuration
                    .multiply(normalizedFraction)
                    .reduce();

                // Utiliser MeasureEditor pour trouver l'eventIndex et isAfterEvent
                final eventInfo = MeasureEditor.findEventIndex(measure, positionInMeasure);
                
                return StaffCursorPosition(
                  measureIndex: measureIndex,
                  eventIndex: eventInfo.index,
                  isAfterEvent: eventInfo.splitEvent || eventInfo.index >= measure.events.length,
                  positionInMeasure: positionInMeasure,
                );
              }
            }
          }

          return null;
        }

        ({int measureIndex, int eventIndex, bool placeAboveLine})?
            resolveTapTarget(TapDownDetails details) {
          if (score.measures.isEmpty) return null;

          // Trouver la note la plus proche en utilisant les bounding boxes
          int? targetMeasureIndex;
          int? targetEventIndex;
          double minDistance = double.infinity;

          for (final system in pageLayoutResult.systems) {
            for (final measureLayout in system.measures) {
              // Trouver l'index de la mesure dans le score
              final measureIndex = score.measures.indexOf(measureLayout.measureModel);
              if (measureIndex < 0) continue;

              // Vérifier si le clic est dans cette mesure
              if (!measureLayout.boundingBox.contains(details.localPosition)) continue;

              // Chercher la note la plus proche dans cette mesure
              for (int noteIndex = 0; noteIndex < measureLayout.notes.length; noteIndex++) {
                final note = measureLayout.notes[noteIndex];
                
                // Utiliser le bounding box de la note pour le hit-testing
                if (note.boundingBox.contains(details.localPosition)) {
                  final double distance = (details.localPosition - note.noteheadPosition).distance;
                  if (distance < minDistance) {
                    minDistance = distance;
                    targetMeasureIndex = measureIndex;
                    targetEventIndex = noteIndex;
                  }
                }
              }
            }
          }

          if (targetMeasureIndex == null || targetEventIndex == null) return null;

          // Déterminer si la note doit être au-dessus de la ligne
          // Trouver le système qui contient cette mesure
          double? centerY;
          for (final system in pageLayoutResult.systems) {
            for (final measureLayout in system.measures) {
              if (measureLayout.measureModel == score.measures[targetMeasureIndex]) {
                centerY = system.staffY;
                break;
              }
            }
            if (centerY != null) break;
          }

          final bool placeAboveLine = centerY != null
              ? details.localPosition.dy <= centerY
              : false;

          return (
            measureIndex: targetMeasureIndex,
            eventIndex: targetEventIndex,
            placeAboveLine: placeAboveLine,
          );
        }


        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {

            // Find measure index that contains the tap position
            print('onTapDown details: $details');
            final cursor = resolveCursor(details.localPosition);

            print('cursor: $cursor');
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
          child: Builder(
            builder: (context) {

              return CustomPaint(
                painter: StaffPainter(
                  score: score,
                  pageLayoutResult: pageLayoutResult,
                  cursorPosition: cursorPosition,
                  selectedNotes: selectedNotes,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      },
    );
  }
}
