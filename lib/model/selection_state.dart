import 'package:flutter/foundation.dart';

import 'duration_fraction.dart';

@immutable
class StaffCursorPosition {
  const StaffCursorPosition({
    required this.measureIndex,
    required this.position,
  });

  final int measureIndex;
  final DurationFraction position;

  StaffCursorPosition copyWith({
    int? measureIndex,
    DurationFraction? position,
  }) {
    return StaffCursorPosition(
      measureIndex: measureIndex ?? this.measureIndex,
      position: position ?? this.position,
    );
  }

  int compareTo(StaffCursorPosition other) {
    if (measureIndex != other.measureIndex) {
      return measureIndex.compareTo(other.measureIndex);
    }
    return position.compareTo(other.position);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffCursorPosition) return false;
    return measureIndex == other.measureIndex && position == other.position;
  }

  @override
  int get hashCode => Object.hash(measureIndex, position);
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

