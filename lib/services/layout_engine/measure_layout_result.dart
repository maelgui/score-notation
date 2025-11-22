import 'package:flutter/material.dart';

import '../../model/measure.dart';
import 'note_layout_result.dart';

/// Résultat du layout d'une mesure.
///
/// Contient toutes les informations nécessaires pour dessiner la mesure,
/// avec positions absolues dans la page.
class MeasureLayoutResult {
  const MeasureLayoutResult({
    required this.measureModel,
    required this.origin,
    required this.width,
    required this.height,
    required this.staffY,
    required this.barlineXStart,
    required this.barlineXEnd,
    required this.boundingBox,
    required this.notes,
    required this.beams,
  });

  /// Référence au modèle métier de la mesure.
  final Measure measureModel;

  /// Position absolue de la mesure dans la page.
  final Offset origin;

  /// Largeur totale de la mesure.
  final double width;

  /// Hauteur totale de la mesure.
  final double height;

  /// Position Y de la ligne de portée (absolue dans la page).
  final double staffY;

  /// Position X du début de la barline (absolue dans la page).
  final double barlineXStart;

  /// Position X de la fin de la barline (absolue dans la page).
  final double barlineXEnd;

  /// Bounding box de la mesure (pour hit-testing).
  final Rect boundingBox;

  /// Liste des notes layoutées avec positions absolues.
  final List<NoteLayoutResult> notes;

  /// Liste des segments de beams.
  final List<LayoutedBeamSegment> beams;
}

/// Représente un segment de beam (ligature).
class LayoutedBeamSegment {
  const LayoutedBeamSegment({
    required this.level,
    required this.startX,
    required this.endX,
    required this.y,
    required this.noteIndices,
    this.tupletNumber,
  });

  /// Niveau du beam (0 = plus bas, 1, 2, 3...).
  final int level;

  /// Position X de début du beam.
  final double startX;

  /// Position X de fin du beam.
  final double endX;

  /// Position Y du beam.
  final double y;

  /// Indices des notes dans le groupe (dans la liste des notes de la mesure).
  final List<int> noteIndices;

  /// Numéro du tuplet à afficher sous ce beam (null si pas de tuplet).
  final int? tupletNumber;

  /// Indique si c'est un beam partiel (coupé).
  bool get isPartial => noteIndices.length == 1;

  /// Indique si c'est un beam normal (continu).
  bool get isNormal => noteIndices.length > 1;
}
