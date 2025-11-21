import 'package:flutter/material.dart';

import '../../model/score.dart';
import '../../utils/constants.dart';
import '../../utils/smufl/engraving_defaults.dart';
import 'layout_engine.dart';
import 'measure_layout_result.dart';
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

    // 1. Répartir les mesures sur plusieurs systèmes
    final List<List<int>> systemMeasures = _distributeMeasuresAcrossStaffs(
      measureCount: score.measures.length,
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

    for (
      int systemIndex = 0;
      systemIndex < systemMeasures.length;
      systemIndex++
    ) {
      final systemMeasureIndices = systemMeasures[systemIndex];
      if (systemMeasureIndices.isEmpty) continue;

      final double staffY = startY + systemIndex * staffSpacing;
      final double systemOriginY = staffY - EngravingDefaults.staffSpace * 2;
      final double systemHeight = EngravingDefaults.staffSpace * 4;

      // Calculer la largeur uniforme pour toutes les mesures de cette ligne
      double uniformMeasureWidth = availableWidth / measuresPerLine;

      // Calculer les mesures avec positions absolues
      final List<MeasureLayoutResult> measures = [];
      double currentX = padding;

      for (final measureIndex in systemMeasureIndices) {
        if (measureIndex >= score.measures.length) continue;

        final measure = score.measures[measureIndex];

        // Position absolue de la mesure
        final Offset measureOrigin = Offset(currentX, systemOriginY);

        // Calculer le layout complet avec positions absolues
        final settings = LayoutSettings(
          noteHeadWidth: EngravingDefaults.noteHeadWidth,
          staffSpace: EngravingDefaults.staffSpace,
          baseUnitFactor: EngravingDefaults.noteSpacingBaseUnitFactor,
          staffY: referenceStaffY,
        );

        final measureLayout = LayoutEngine.layoutMeasure(
          measure,
          settings,
          measureOrigin,
          uniformMeasureWidth,
          staffY,
          systemHeight,
          referenceStaffY,
        );

        measures.add(measureLayout);

        currentX = measureLayout.barlineXEnd;
      }

      // Calculer les dimensions du système
      final double systemWidth = measures.isNotEmpty
          ? measures.last.origin.dx +
                measures.last.width -
                measures.first.origin.dx
          : availableWidth;
      final Offset systemOrigin = Offset(padding, systemOriginY);

      systems.add(
        StaffLayoutResult(
          systemIndex: systemIndex,
          origin: systemOrigin,
          width: systemWidth,
          height: systemHeight,
          staffY: staffY,
          measures: measures,
        ),
      );
    }

    return PageLayoutResult(
      pageIndex: 0,
      width: pageWidth,
      height: pageHeight,
      origin: Offset.zero,
      systems: systems,
    );
  }


  /// Répartit les mesures sur plusieurs systèmes.
  ///
  /// Si [measuresPerLine] est fourni et > 0, utilise ce nombre fixe par ligne.
  /// Sinon, calcule automatiquement selon la largeur disponible.
  static List<List<int>> _distributeMeasuresAcrossStaffs({
    required int measureCount,
    required int measuresPerLine,
  }) {
    final List<List<int>> systemMeasures = [];

    // Si un nombre fixe de mesures par ligne est défini, l'utiliser
    for (int i = 0; i < measureCount; i += measuresPerLine) {
      final end = (i + measuresPerLine < measureCount)
          ? i + measuresPerLine
          : measureCount;
      systemMeasures.add(List.generate(end - i, (j) => i + j));
    }
    return systemMeasures;
  }
}
