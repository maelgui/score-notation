import '../../model/measure.dart';
import '../../model/note_event.dart';
import '../../model/duration_fraction.dart';
import '../../utils/measure_editor.dart';
import '../../utils/smufl/engraving_defaults.dart';
import 'beam_engine.dart';
import 'measure_layout_result.dart';
import 'spacing_engine.dart';
import 'stem_engine.dart';

/// Settings pour le layout d'une mesure
class LayoutSettings {
  const LayoutSettings({
    required this.minWidth,
    required this.noteHeadWidth,
    required this.staffSpace,
    required this.baseUnitFactor,
    required this.staffY,
  });

  final double minWidth;
  final double noteHeadWidth;
  final double staffSpace;
  final double baseUnitFactor;
  final double staffY;
}

/// Données brutes retournées par LayoutEngine pour construire NoteLayoutResult.
class NoteLayoutData {
  const NoteLayoutData({
    required this.event,
    required this.x,
    required this.y,
    required this.isBeamed,
    this.stemX,
    this.stemStartY,
    this.stemEndY,
  });

  final NoteEvent event;
  final double x;
  final double y;
  final bool isBeamed;
  final double? stemX;
  final double? stemStartY;
  final double? stemEndY;
}

/// Données brutes retournées par LayoutEngine.
class MeasureLayoutData {
  const MeasureLayoutData({
    required this.width,
    required this.notes,
    required this.beams,
  });

  final double width;
  final List<NoteLayoutData> notes;
  final List<LayoutedBeamSegment> beams;
}

/// Point d'entrée principal du Layout Engine.
/// Orchestre tous les engines pour calculer le layout d'une mesure.
class LayoutEngine {
  LayoutEngine._();

  /// Calcule le layout d'une mesure et retourne les données brutes.
  /// Les positions sont relatives (seront converties en absolues par PageEngine).
  static MeasureLayoutData layoutMeasure(
    Measure measure,
    LayoutSettings settings,
  ) {
    // 1. Calculer la largeur naturelle et la largeur finale
    final double naturalWidth = SpacingEngine.computeNaturalWidth(
      measure,
      settings.noteHeadWidth,
      settings.baseUnitFactor,
    );
    final double measureWidth = naturalWidth > settings.minWidth
        ? naturalWidth
        : settings.minWidth;

    // 2. Calculer les positions X des notes
    final notePositions = SpacingEngine.computeNotePositions(
      measure,
      measureWidth,
      0.0,
    );

    // 3. Extraire les événements avec leurs positions pour le beam engine
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);
    final notePositionsWithEvents = <({double x, NoteEvent event, DurationFraction position})>[];
    
    for (int i = 0; i < notePositions.length && i < eventsWithPositions.length; i++) {
      final pos = notePositions[i];
      final eventPos = eventsWithPositions[i];
      notePositionsWithEvents.add((
        x: pos.x,
        event: eventPos.event,
        position: eventPos.position,
      ));
    }

    // 4. Trouver les groupes de beams
    final beamGroups = BeamEngine.findBeamGroups(notePositionsWithEvents, measure);
    final Set<int> beamedNoteIndices = {};
    for (final group in beamGroups) {
      beamedNoteIndices.addAll(group);
    }
    
    // 5. Calculer les segments de beams
    final beamSegments = BeamEngine.computeBeamSegments(
      notePositionsWithEvents,
      beamGroups,
      settings.staffY,
    );
    
    // Calculer beamBaseY pour les hampes beamed
    double? beamBaseY;
    if (beamSegments.isNotEmpty) {
      final double stemLength = EngravingDefaults.stemLength;
      beamBaseY = settings.staffY + stemLength;
    }

    // 6. Créer les données de layout des notes
    final List<NoteLayoutData> notes = [];
    for (int i = 0; i < notePositions.length && i < measure.events.length; i++) {
      final pos = notePositions[i];
      final event = measure.events[i];
      final isBeamed = beamedNoteIndices.contains(i);
      
      // Calculer la position Y
      final double noteY = StemEngine.computeNoteCenterY(event, settings.staffY);
      
      // Calculer les positions de la hampe
      final stemPos = StemEngine.computeStemPosition(
        pos.x,
        noteY,
        event,
        settings.staffY,
        isBeamed,
        beamBaseY,
      );

      notes.add(NoteLayoutData(
        event: event,
        x: pos.x,
        y: noteY,
        isBeamed: isBeamed,
        stemX: event.isRest ? null : stemPos.x,
        stemStartY: event.isRest ? null : stemPos.startY,
        stemEndY: event.isRest ? null : stemPos.endY,
      ));
    }

    return MeasureLayoutData(
      width: measureWidth,
      notes: notes,
      beams: beamSegments,
    );
  }
}
