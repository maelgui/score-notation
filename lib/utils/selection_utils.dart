import 'package:flutter/rendering.dart';

import '../model/duration_fraction.dart';
import '../model/selection_state.dart';
import '../model/score.dart';
import '../services/layout_engine/page_engine.dart';
import '../utils/constants.dart';
import '../utils/measure_editor.dart';
import '../utils/smufl/engraving_defaults.dart';
import 'measure_helper.dart';

class SelectionUtils {
  SelectionUtils._();

  static const int _cursorPrecision = 2048;

  /// Calcule la position du curseur depuis un offset, en utilisant la nouvelle structure avec bounding boxes.
  static StaffCursorPosition? cursorFromOffset({
    required Score score,
    required double maxWidth,
    required Offset localPosition,
    double? maxHeight,
    int measuresPerLine = 4,
  }) {
    if (score.measures.isEmpty) return null;
    final double padding = AppConstants.staffPadding;
    final double availableWidth = (maxWidth - 2 * padding).clamp(0.0, double.infinity);
    if (availableWidth <= 0) return null;

    final double referenceStaffY = maxHeight != null ? maxHeight / 2 : 0.0;
    final double sizeHeight = maxHeight ?? 800.0; // Valeur par défaut si null

    // Utiliser PageEngine pour obtenir le layout avec positions absolues
    final pageLayoutResult = PageEngine.layoutPage(
      score: score,
      measuresPerLine: measuresPerLine,
      availableWidth: availableWidth,
      padding: padding,
      referenceStaffY: referenceStaffY,
      sizeHeight: sizeHeight,
    );

    // Trouver la mesure qui contient cette position en utilisant les bounding boxes
    for (final system in pageLayoutResult.systems) {
      for (final measureLayout in system.measures) {
        final measureRect = Rect.fromLTWH(
          measureLayout.origin.dx,
          measureLayout.origin.dy,
          measureLayout.width,
          measureLayout.height,
        );

        if (measureRect.contains(localPosition)) {
          // Trouver l'index de la mesure dans le score
          final measureIndex = score.measures.indexOf(measureLayout.measureModel);
          if (measureIndex < 0) continue;

          // Calculer la position normalisée dans la mesure
          final double relativeX = localPosition.dx - measureLayout.barlineXStart;
          final double notesStartX = measureLayout.barlineXStart + EngravingDefaults.spaceBeforeBarline;
          final double notesEndX = measureLayout.barlineXEnd - EngravingDefaults.spaceBeforeBarline;
          final double notesSpan = notesEndX - notesStartX;

          if (notesSpan <= 0) continue;

          final double normalized = ((relativeX - EngravingDefaults.spaceBeforeBarline) / notesSpan).clamp(0.0, 1.0);
          final measure = measureLayout.measureModel;
          final DurationFraction positionInMeasure = _normalizedToDuration(measure.maxDuration, normalized);

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


  static Set<NoteSelectionReference> notesWithinRange(
    Score score,
    SelectionRange? range,
  ) {
    if (range == null || score.measures.isEmpty) {
      return const {};
    }

    final normalizedRange = range.normalize();
    final result = <NoteSelectionReference>{};
    final startIndex = normalizedRange.start.measureIndex.clamp(0, score.measures.length - 1);
    final endIndex = normalizedRange.end.measureIndex.clamp(0, score.measures.length - 1);

    for (int measureIndex = startIndex; measureIndex <= endIndex; measureIndex++) {
      final measure = score.measures[measureIndex];
      final entries = MeasureEditor.extractEventsWithPositions(measure);
      for (int eventIndex = 0; eventIndex < entries.length; eventIndex++) {
      final entry = entries[eventIndex];
      if (entry.event.isRest) continue;

      // Créer un cursor position à la position de l'événement
      final candidate = StaffCursorPosition(
        measureIndex: measureIndex,
        eventIndex: eventIndex,
        isAfterEvent: false,
        positionInMeasure: entry.position,
      );

        final bool isAfterStart = candidate.compareTo(normalizedRange.start) >= 0;
        final bool isBeforeEnd = candidate.compareTo(normalizedRange.end) <= 0;

        if (isAfterStart && isBeforeEnd) {
          result.add(
            NoteSelectionReference(
              measureIndex: measureIndex,
              eventIndex: eventIndex,
            ),
          );
        }
      }
    }

    return result;
  }

  static DurationFraction _normalizedToDuration(
    DurationFraction maxDuration,
    double normalized,
  ) {
    final clamped = normalized.clamp(0.0, 1.0);
    final normalizedFraction =
        DurationFraction((clamped * _cursorPrecision).round(), _cursorPrecision);
    return maxDuration.multiply(normalizedFraction).reduce();
  }

  static double positionToNormalizedX({
    required DurationFraction position,
    required DurationFraction maxDuration,
  }) {
    final double positionValue = MeasureHelper.fractionToPosition(position);
    final double maxDurationValue = MeasureHelper.fractionToPosition(maxDuration);
    if (maxDurationValue == 0) return 0.0;
    return (positionValue / maxDurationValue).clamp(0.0, 1.0);
  }
}

