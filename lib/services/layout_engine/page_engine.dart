import 'package:flutter/material.dart';

import '../../model/measure.dart';
import '../../model/score.dart';
import '../../utils/constants.dart';
import '../../utils/note_event_helper.dart';
import '../../utils/smufl/engraving_defaults.dart';
import 'layout_engine.dart';
import 'measure_layout_result.dart';
import 'note_layout_result.dart';
import 'page_layout_result.dart';
import 'staff_layout_result.dart';

/// Engine responsable du layout d'une page complète.
///
/// Calcule la répartition des mesures sur plusieurs portées et leurs positions.
class PageEngine {
  PageEngine._();

  /// Calcule le layout complet d'une page.
  ///
  /// Paramètres:
  /// - [score]: Le score à layout
  /// - [measuresPerLine]: Nombre de mesures par ligne (si > 0, utilise ce nombre fixe)
  /// - [availableWidth]: Largeur disponible pour les mesures (sans padding)
  /// - [padding]: Padding horizontal
  /// - [referenceStaffY]: Position Y de référence pour le calcul des layouts (généralement height/2)
  /// - [sizeHeight]: Hauteur totale disponible
  static PageLayoutResult layoutPage({
    required Score score,
    required int measuresPerLine,
    required double availableWidth,
    required double padding,
    required double referenceStaffY,
    required double sizeHeight,
  }) {
    if (score.measures.isEmpty) {
      return PageLayoutResult(
        pageIndex: 0,
        width: availableWidth + 2 * padding,
        height: sizeHeight,
        origin: Offset.zero,
        systems: [],
      );
    }

    // 1. Calculer les layouts de base de toutes les mesures (positions relatives)
    final List<_MeasureData> measureDataList = [];
    final double minMeasureWidth =
        EngravingDefaults.noteHeadWidth *
        EngravingDefaults.minMeasureWidthFactor;

    for (int i = 0; i < score.measures.length; i++) {
      final measure = score.measures[i];
      final settings = LayoutSettings(
        minWidth: minMeasureWidth,
        noteHeadWidth: EngravingDefaults.noteHeadWidth,
        staffSpace: EngravingDefaults.staffSpace,
        baseUnitFactor: EngravingDefaults.noteSpacingBaseUnitFactor,
        staffY: referenceStaffY,
      );
      final layoutData = LayoutEngine.layoutMeasure(measure, settings);
      measureDataList.add(_MeasureData(
        measure: measure,
        layoutData: layoutData,
      ));
    }

    // 2. Répartir les mesures sur plusieurs systèmes
    final List<List<int>> systemMeasures = _distributeMeasuresAcrossStaffs(
      measureDataList: measureDataList,
      availableWidth: availableWidth,
      measuresPerLine: measuresPerLine,
    );

    // 3. Calculer la position Y de départ
    final double staffSpacing = AppConstants.staffSpacing;
    final int totalSystems = systemMeasures.length;
    final double totalHeight = totalSystems * staffSpacing;
    final double startY = (sizeHeight - totalHeight) / 2 + staffSpacing / 2;

    // 4. Calculer le layout de chaque système avec positions absolues
    final List<StaffLayoutResult> systems = [];
    final double pageWidth = availableWidth + 2 * padding;
    final double pageHeight = sizeHeight;

    for (int systemIndex = 0; systemIndex < systemMeasures.length; systemIndex++) {
      final systemMeasureIndices = systemMeasures[systemIndex];
      if (systemMeasureIndices.isEmpty) continue;

      final double staffY = startY + systemIndex * staffSpacing;
      final double systemOriginY = staffY - EngravingDefaults.staffSpace * 2;
      final double systemHeight = EngravingDefaults.staffSpace * 4;

      // Calculer la largeur uniforme pour toutes les mesures de cette ligne
      double uniformMeasureWidth = 0.0;
      if (measuresPerLine > 0 && systemMeasureIndices.isNotEmpty) {
        final double totalBarSpacing =
            (systemMeasureIndices.length - 1) * AppConstants.barSpacing;
        final double totalMeasuresWidth = availableWidth - totalBarSpacing;
        uniformMeasureWidth = totalMeasuresWidth / systemMeasureIndices.length;
      }

      // Calculer les mesures avec positions absolues
      final List<MeasureLayoutResult> measures = [];
      double currentX = padding;

      for (final measureIndex in systemMeasureIndices) {
        if (measureIndex >= measureDataList.length) continue;

        final data = measureDataList[measureIndex];
        final layoutData = data.layoutData;
        final measure = data.measure;

        // Calculer la largeur de la mesure
        final double measureWidth = uniformMeasureWidth > 0
            ? uniformMeasureWidth
            : layoutData.width;
        final double stretchFactor = uniformMeasureWidth > 0 && layoutData.width > 0
            ? uniformMeasureWidth / layoutData.width
            : 1.0;

        // Position absolue de la mesure
        final Offset measureOrigin = Offset(currentX, systemOriginY);
        final double barlineXStart = currentX;
        final double barlineXEnd = currentX + measureWidth;

        // Convertir les données de layout en NoteLayoutResult avec positions absolues
        final List<NoteLayoutResult> notes = [];
        for (int i = 0; i < layoutData.notes.length && i < measure.events.length; i++) {
          final noteData = layoutData.notes[i];
          final event = noteData.event;

          // Position absolue de la notehead
          final double noteX = measureOrigin.dx +
              EngravingDefaults.spaceBeforeBarline +
              noteData.x * stretchFactor;
          final double noteY = staffY + (noteData.y - referenceStaffY);
          final Offset noteheadPosition = Offset(noteX, noteY);

          // Calculer les positions absolues de la hampe
          final double? absoluteStemX = noteData.stemX != null
              ? measureOrigin.dx +
                  EngravingDefaults.spaceBeforeBarline +
                  noteData.stemX! * stretchFactor
              : null;
          final double? absoluteStemTopY = noteData.stemStartY != null
              ? staffY + (noteData.stemStartY! - referenceStaffY)
              : null;
          final double? absoluteStemBottomY = noteData.stemEndY != null
              ? staffY + (noteData.stemEndY! - referenceStaffY)
              : null;

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
          if (noteData.isBeamed) {
            // Trouver le beam correspondant
            for (final beam in layoutData.beams) {
              if (beam.noteIndices.contains(i)) {
                beamLevel = beam.level;
                beamStartsGroup = beam.noteIndices.first == i;
                beamEndsGroup = beam.noteIndices.last == i;
                break;
              }
            }
          }

          notes.add(NoteLayoutResult(
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
          ));
        }

        // Convertir les beams avec positions absolues
        final List<LayoutedBeamSegment> absoluteBeams = layoutData.beams.map((beam) {
          return LayoutedBeamSegment(
            level: beam.level,
            startX: measureOrigin.dx +
                EngravingDefaults.spaceBeforeBarline +
                beam.startX * stretchFactor,
            endX: measureOrigin.dx +
                EngravingDefaults.spaceBeforeBarline +
                beam.endX * stretchFactor,
            y: staffY + (beam.y - referenceStaffY),
            noteIndices: beam.noteIndices,
          );
        }).toList();

        // Calculer le bounding box de la mesure
        final measureBoundingBox = Rect.fromLTWH(
          measureOrigin.dx,
          measureOrigin.dy,
          measureWidth,
          systemHeight,
        );

        measures.add(MeasureLayoutResult(
          measureModel: measure,
          origin: measureOrigin,
          width: measureWidth,
          height: systemHeight,
          staffY: staffY,
          barlineXStart: barlineXStart,
          barlineXEnd: barlineXEnd,
          boundingBox: measureBoundingBox,
          notes: notes,
          beams: absoluteBeams,
        ));

        currentX = barlineXEnd + AppConstants.barSpacing;
      }

      // Calculer les dimensions du système
      final double systemWidth = measures.isNotEmpty
          ? measures.last.origin.dx + measures.last.width - measures.first.origin.dx
          : availableWidth;
      final Offset systemOrigin = Offset(padding, systemOriginY);

      systems.add(StaffLayoutResult(
        systemIndex: systemIndex,
        origin: systemOrigin,
        width: systemWidth,
        height: systemHeight,
        staffY: staffY,
        measures: measures,
      ));
    }

    return PageLayoutResult(
      pageIndex: 0,
      width: pageWidth,
      height: pageHeight,
      origin: Offset.zero,
      systems: systems,
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

  /// Répartit les mesures sur plusieurs systèmes.
  ///
  /// Si [measuresPerLine] est fourni et > 0, utilise ce nombre fixe par ligne.
  /// Sinon, calcule automatiquement selon la largeur disponible.
  static List<List<int>> _distributeMeasuresAcrossStaffs({
    required List<_MeasureData> measureDataList,
    required double availableWidth,
    required int measuresPerLine,
  }) {
    final List<List<int>> systemMeasures = [];

    // Si un nombre fixe de mesures par ligne est défini, l'utiliser
    if (measuresPerLine > 0) {
      for (int i = 0; i < measureDataList.length; i += measuresPerLine) {
        final end = (i + measuresPerLine < measureDataList.length)
            ? i + measuresPerLine
            : measureDataList.length;
        systemMeasures.add(List.generate(end - i, (j) => i + j));
      }
      return systemMeasures;
    }

    // Sinon, calculer automatiquement selon la largeur disponible
    List<int> currentSystem = [];
    double currentWidth = 0.0;

    for (int i = 0; i < measureDataList.length; i++) {
      final layoutData = measureDataList[i].layoutData;
      final double measureWidthWithSpacing = layoutData.width + AppConstants.barSpacing;

      if (currentWidth + measureWidthWithSpacing > availableWidth &&
          currentSystem.isNotEmpty) {
        systemMeasures.add(List.from(currentSystem));
        currentSystem = [];
        currentWidth = 0.0;
      }

      currentSystem.add(i);
      currentWidth += measureWidthWithSpacing;
    }

    if (currentSystem.isNotEmpty) {
      systemMeasures.add(currentSystem);
    }

    return systemMeasures;
  }
}

/// Données pour le layout d'une mesure.
class _MeasureData {
  const _MeasureData({
    required this.measure,
    required this.layoutData,
  });

  final Measure measure;
  final MeasureLayoutData layoutData;
}
