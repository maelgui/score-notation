import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../model/duration_fraction.dart';
import '../model/selection_state.dart';
import '../model/score.dart';
import '../utils/constants.dart';
import 'measure_editor.dart';
import 'measure_helper.dart';

class SelectionUtils {
  SelectionUtils._();

  static const int _cursorPrecision = 2048;

  static StaffCursorPosition? cursorFromOffset({
    required Score score,
    required double maxWidth,
    required Offset localPosition,
  }) {
    if (score.measures.isEmpty) return null;
    final double padding = AppConstants.staffPadding;
    final double availableWidth = (maxWidth - 2 * padding).clamp(0.0, double.infinity);
    if (availableWidth <= 0) return null;

    final int measureCount = math.max(score.measures.length, 1);
    final double measureWidth = availableWidth / measureCount;
    final double relativeX = (localPosition.dx - padding).clamp(0.0, availableWidth);
    int measureIndex = (relativeX / measureWidth).floor();
    measureIndex = measureIndex.clamp(0, score.measures.length - 1);

    final double localXInMeasure = relativeX - measureIndex * measureWidth;
    final double notesStartX = AppConstants.spaceBeforeBarline;
    final double notesEndX =
        measureWidth - AppConstants.barSpacing - AppConstants.spaceBeforeBarline;
    final double notesSpan = notesEndX - notesStartX;

    double normalized = 0.0;
    if (notesSpan > 0) {
      normalized = ((localXInMeasure - notesStartX) / notesSpan).clamp(0.0, 1.0);
    }

    final measure = score.measures[measureIndex];
    final DurationFraction position =
        _normalizedToDuration(measure.maxDuration, normalized);

    return StaffCursorPosition(measureIndex: measureIndex, position: position);
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

        final candidate = StaffCursorPosition(
          measureIndex: measureIndex,
          position: entry.position,
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

