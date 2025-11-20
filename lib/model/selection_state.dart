import 'package:flutter/foundation.dart';

import 'duration_fraction.dart';

@immutable
class StaffCursorPosition {
  const StaffCursorPosition({
    required this.measureIndex,
    required this.eventIndex,
    required this.isAfterEvent,
    required this.positionInMeasure,
  });

  /// Index de la mesure dans le score.
  final int measureIndex;

  /// Index de l'événement dans la mesure (ou events.length si après tous les événements).
  final int eventIndex;

  /// True si le curseur est après l'événement (entre eventIndex et eventIndex+1).
  /// False si le curseur est avant l'événement (au début de eventIndex).
  final bool isAfterEvent;

  /// Position rythmique dans la mesure (depuis le début de la mesure).
  final DurationFraction positionInMeasure;

  StaffCursorPosition copyWith({
    int? measureIndex,
    int? eventIndex,
    bool? isAfterEvent,
    DurationFraction? positionInMeasure,
  }) {
    return StaffCursorPosition(
      measureIndex: measureIndex ?? this.measureIndex,
      eventIndex: eventIndex ?? this.eventIndex,
      isAfterEvent: isAfterEvent ?? this.isAfterEvent,
      positionInMeasure: positionInMeasure ?? this.positionInMeasure,
    );
  }

  /// Compare deux positions (pour les ranges de sélection).
  int compareTo(StaffCursorPosition other) {
    if (measureIndex != other.measureIndex) {
      return measureIndex.compareTo(other.measureIndex);
    }
    return positionInMeasure.compareTo(other.positionInMeasure);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffCursorPosition) return false;
    return measureIndex == other.measureIndex &&
        eventIndex == other.eventIndex &&
        isAfterEvent == other.isAfterEvent &&
        positionInMeasure == other.positionInMeasure;
  }

  @override
  int get hashCode => Object.hash(
        measureIndex,
        eventIndex,
        isAfterEvent,
        positionInMeasure,
      );

  @override
  String toString() =>
      'StaffCursorPosition(measureIndex: $measureIndex, eventIndex: $eventIndex, '
      'isAfterEvent: $isAfterEvent, positionInMeasure: $positionInMeasure)';
}

@immutable
class NoteSelectionReference {
  const NoteSelectionReference({
    required this.measureIndex,
    required this.eventIndex,
  });

  final int measureIndex;
  final int eventIndex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteSelectionReference) return false;
    return measureIndex == other.measureIndex && eventIndex == other.eventIndex;
  }

  @override
  int get hashCode => Object.hash(measureIndex, eventIndex);
}

@immutable
class SelectionRange {
  const SelectionRange({
    required this.start,
    required this.end,
  });

  final StaffCursorPosition start;
  final StaffCursorPosition end;

  SelectionRange normalize() {
    if (start.compareTo(end) <= 0) {
      return this;
    }
    return SelectionRange(start: end, end: start);
  }

  bool get isCollapsed => start == end;

  StaffCursorPosition get min => normalize().start;

  StaffCursorPosition get max => normalize().end;

  bool containsPosition(StaffCursorPosition position) {
    final normalized = normalize();
    return position.compareTo(normalized.start) >= 0 &&
        position.compareTo(normalized.end) <= 0;
  }
}

@immutable
class SelectionState {
  SelectionState({
    this.cursor,
    this.range,
    Set<NoteSelectionReference> selectedNotes = const {},
  }) : selectedNotes = Set.unmodifiable(selectedNotes);

  final StaffCursorPosition? cursor;
  final SelectionRange? range;
  final Set<NoteSelectionReference> selectedNotes;

  SelectionState copyWith({
    StaffCursorPosition? cursor,
    SelectionRange? range,
    Set<NoteSelectionReference>? selectedNotes,
    bool clearCursor = false,
    bool clearRange = false,
    bool clearSelectedNotes = false,
  }) {
    return SelectionState(
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      range: clearRange ? null : (range ?? this.range),
      selectedNotes:
          clearSelectedNotes ? const {} : (selectedNotes ?? this.selectedNotes),
    );
  }
}

