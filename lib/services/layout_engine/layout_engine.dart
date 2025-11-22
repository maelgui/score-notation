import 'package:flutter/material.dart';

import '../../model/measure.dart';
import '../../model/note_event.dart';
import '../../model/duration_fraction.dart';
import '../../utils/measure_editor.dart';
import '../../utils/note_event_helper.dart';
import '../../utils/smufl/engraving_defaults.dart';
import 'beam_engine.dart';
import 'measure_layout_result.dart';
import 'note_layout_result.dart';
import 'spacing_engine.dart';
import 'stem_engine.dart';

/// Settings pour le layout d'une mesure
class LayoutSettings {
  const LayoutSettings({
    required this.noteHeadWidth,
    required this.staffSpace,
    required this.baseUnitFactor,
    required this.staffY,
  });

  final double noteHeadWidth;
  final double staffSpace;
  final double baseUnitFactor;
  final double staffY;
}

/// Point d'entrée principal du Layout Engine.
/// Orchestre tous les engines pour calculer le layout d'une mesure.
class LayoutEngine {
  LayoutEngine._();

  /// Calcule le layout complet d'une mesure avec positions absolues.
  ///
  /// [measure] : La mesure à layout
  /// [settings] : Paramètres de layout
  /// [measureOrigin] : Position absolue de la mesure dans la page
  /// [uniformMeasureWidth] : Largeur uniforme de la mesure (peut être différente de la largeur naturelle)
  /// [absoluteStaffY] : Position Y absolue de la ligne de portée
  /// [systemHeight] : Hauteur du système
  /// [referenceStaffY] : Position Y de référence utilisée pour les calculs relatifs
  static MeasureLayoutResult layoutMeasure(
    Measure measure,
    LayoutSettings settings,
    Offset measureOrigin,
    double uniformMeasureWidth,
    double absoluteStaffY,
    double systemHeight,
    double referenceStaffY,
  ) {
    // 1. Calculer les positions X des notes directement avec uniformMeasureWidth
    final notePositions = SpacingEngine.computeNotePositions(
      measure,
      uniformMeasureWidth,
      0.0,
    );

    // 2. Extraire les événements avec leurs positions pour le beam engine
    final eventsWithPositions = MeasureEditor.extractEventsWithPositions(
      measure,
    );
    final notePositionsWithEvents =
        <({double x, NoteEvent event, DurationFraction position})>[];

    for (
      int i = 0;
      i < notePositions.length && i < eventsWithPositions.length;
      i++
    ) {
      final pos = notePositions[i];
      final eventPos = eventsWithPositions[i];
      notePositionsWithEvents.add((
        x: pos.x,
        event: eventPos.event,
        position: eventPos.position,
      ));
    }

    // 3. Trouver les groupes de beams
    final beamGroups = BeamEngine.findBeamGroups(
      notePositionsWithEvents,
      measure,
    );
    final Set<int> beamedNoteIndices = {};
    for (final group in beamGroups) {
      beamedNoteIndices.addAll(group);
    }

    // 4. Calculer les segments de beams (avec positions relatives)
    final relativeBeamSegments = BeamEngine.computeBeamSegments(
      notePositionsWithEvents,
      beamGroups,
      referenceStaffY,
    );

    // Calculer beamBaseY pour les hampes beamed
    double? beamBaseY;
    if (relativeBeamSegments.isNotEmpty) {
      final double stemLength = EngravingDefaults.stemLength;
      beamBaseY = referenceStaffY + stemLength;
    }

    // 5. Créer les NoteLayoutResult avec positions absolues
    final List<NoteLayoutResult> notes = [];
    for (
      int i = 0;
      i < notePositions.length && i < measure.events.length;
      i++
    ) {
      final pos = notePositions[i];
      final event = measure.events[i];
      final isBeamed = beamedNoteIndices.contains(i);

      // Calculer la position Y relative
      final double relativeNoteY = StemEngine.computeNoteCenterY(
        event,
        referenceStaffY,
      );

      // Calculer les positions de la hampe (relatives)
      final stemPos = StemEngine.computeStemPosition(
        pos.x,
        relativeNoteY,
        event,
        referenceStaffY,
        isBeamed,
        beamBaseY,
      );

      // Convertir en positions absolues (pos.x est déjà calculé avec uniformMeasureWidth)
      final double noteX =
          measureOrigin.dx + EngravingDefaults.spaceBeforeBarline + pos.x;
      final double noteY = absoluteStaffY + (relativeNoteY - referenceStaffY);
      final Offset noteheadPosition = Offset(noteX, noteY);

      final double? absoluteStemX = event.isRest
          ? null
          : measureOrigin.dx + EngravingDefaults.spaceBeforeBarline + stemPos.x;
      final double? absoluteStemTopY = event.isRest
          ? null
          : absoluteStaffY + (stemPos.startY - referenceStaffY);
      final double? absoluteStemBottomY = event.isRest
          ? null
          : absoluteStaffY + (stemPos.endY - referenceStaffY);

      // Calculer le bounding box
      final String glyph = NoteEventHelper.getSymbol(event);
      final Rect boundingBox = _calculateNoteBoundingBox(
        glyph: glyph,
        noteheadPosition: noteheadPosition,
        isRest: event.isRest,
        stemX: absoluteStemX,
        stemTopY: absoluteStemTopY,
        stemBottomY: absoluteStemBottomY,
      );

      // Calculer les informations de beam
      int beamLevel = 0;
      bool beamStartsGroup = false;
      bool beamEndsGroup = false;
      if (isBeamed) {
        // Trouver le beam correspondant
        for (final beam in relativeBeamSegments) {
          if (beam.noteIndices.contains(i)) {
            beamLevel = beam.level;
            beamStartsGroup = beam.noteIndices.first == i;
            beamEndsGroup = beam.noteIndices.last == i;
            break;
          }
        }
      }

      notes.add(
        NoteLayoutResult(
          noteModel: event,
          noteheadPosition: noteheadPosition,
          boundingBox: boundingBox,
          stemX: absoluteStemX ?? noteX,
          stemTopY: absoluteStemTopY ?? noteY,
          stemBottomY: absoluteStemBottomY ?? noteY,
          beamLevel: beamLevel,
          beamStartsGroup: beamStartsGroup,
          beamEndsGroup: beamEndsGroup,
          graceNotes: const [],
        ),
      );
    }

    // 6. Convertir les beams en positions absolues
    final List<LayoutedBeamSegment> absoluteBeams = relativeBeamSegments.map((
      beam,
    ) {
      return LayoutedBeamSegment(
        level: beam.level,
        startX:
            measureOrigin.dx +
            EngravingDefaults.spaceBeforeBarline +
            beam.startX,
        endX:
            measureOrigin.dx + EngravingDefaults.spaceBeforeBarline + beam.endX,
        y: absoluteStaffY + (beam.y - referenceStaffY),
        noteIndices: beam.noteIndices,
        tupletNumber: beam.tupletNumber,
      );
    }).toList();

    // 7. Calculer les positions des barlines et le bounding box
    final double barlineXStart = measureOrigin.dx;
    final double barlineXEnd = measureOrigin.dx + uniformMeasureWidth;
    final Rect boundingBox = Rect.fromLTWH(
      measureOrigin.dx,
      measureOrigin.dy,
      uniformMeasureWidth,
      systemHeight,
    );

    return MeasureLayoutResult(
      measureModel: measure,
      origin: measureOrigin,
      width: uniformMeasureWidth,
      height: systemHeight,
      staffY: absoluteStaffY,
      barlineXStart: barlineXStart,
      barlineXEnd: barlineXEnd,
      boundingBox: boundingBox,
      notes: notes,
      beams: absoluteBeams,
    );
  }

  /// Calcule le bounding box d'une note pour le hit-testing.
  static Rect _calculateNoteBoundingBox({
    required String glyph,
    required Offset noteheadPosition,
    required bool isRest,
    required double? stemX,
    required double? stemTopY,
    required double? stemBottomY,
  }) {
    final double fontSize = EngravingDefaults.symbolFontSize;
    final double glyphWidth = fontSize * 0.8; // Approximation
    final double glyphHeight = fontSize;

    // Bounding box de base autour de la notehead
    double left = noteheadPosition.dx - glyphWidth / 2;
    double top = noteheadPosition.dy - glyphHeight / 2;
    double right = noteheadPosition.dx + glyphWidth / 2;
    double bottom = noteheadPosition.dy + glyphHeight / 2;

    // Si la note a une hampe, étendre le bounding box
    if (!isRest && stemX != null && stemTopY != null && stemBottomY != null) {
      left = left < stemX ? left : stemX - 2;
      right = right > stemX ? right : stemX + 2;
      top = top < stemTopY ? top : stemTopY;
      bottom = bottom > stemBottomY ? bottom : stemBottomY;
    }

    // Ajouter un padding pour faciliter le hit-testing
    const double padding = 4.0;
    return Rect.fromLTRB(
      left - padding,
      top - padding,
      right + padding,
      bottom + padding,
    );
  }
}
