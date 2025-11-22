import 'package:flutter/material.dart';

import '../../model/note_event.dart';

/// Résultat du layout d'une note.
///
/// Contient toutes les informations nécessaires pour dessiner et hit-tester une note,
/// avec positions absolues dans la page.
class NoteLayoutResult {
  const NoteLayoutResult({
    required this.noteModel,
    required this.noteheadPosition,
    required this.boundingBox,
    required this.stemX,
    required this.stemTopY,
    required this.stemBottomY,
  });

  /// Référence au modèle métier de la note.
  final NoteEvent noteModel;

  /// Position absolue du centre de la notehead dans la page.
  final Offset noteheadPosition;

  /// Bounding box complète de la note (pour hit-testing).
  final Rect boundingBox;

  /// Position X de la hampe (si présente).
  final double stemX;

  /// Position Y du haut de la hampe.
  final double stemTopY;

  /// Position Y du bas de la hampe.
  final double stemBottomY;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteLayoutResult) return false;
    return noteModel == other.noteModel &&
        noteheadPosition == other.noteheadPosition &&
        boundingBox == other.boundingBox &&
        stemX == other.stemX &&
        stemTopY == other.stemTopY &&
        stemBottomY == other.stemBottomY;
  }

  @override
  int get hashCode => Object.hash(
        noteModel,
        noteheadPosition,
        boundingBox,
        stemX,
        stemTopY,
        stemBottomY,
      );
}
