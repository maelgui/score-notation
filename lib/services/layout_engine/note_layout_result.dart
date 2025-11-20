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
    required this.beamLevel,
    required this.beamStartsGroup,
    required this.beamEndsGroup,
    this.graceNotes = const [],
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

  /// Niveau du beam (0 = croche, 1 = double, 2 = triple, etc.).
  /// 0 si la note n'est pas beamed.
  final int beamLevel;

  /// True si cette note commence un groupe de beams.
  final bool beamStartsGroup;

  /// True si cette note termine un groupe de beams.
  final bool beamEndsGroup;

  /// Grace notes attachées (pour usage futur).
  final List<GraceNoteLayout> graceNotes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteLayoutResult) return false;
    return noteModel == other.noteModel &&
        noteheadPosition == other.noteheadPosition &&
        boundingBox == other.boundingBox &&
        stemX == other.stemX &&
        stemTopY == other.stemTopY &&
        stemBottomY == other.stemBottomY &&
        beamLevel == other.beamLevel &&
        beamStartsGroup == other.beamStartsGroup &&
        beamEndsGroup == other.beamEndsGroup &&
        _listEquals(graceNotes, other.graceNotes);
  }

  @override
  int get hashCode => Object.hash(
        noteModel,
        noteheadPosition,
        boundingBox,
        stemX,
        stemTopY,
        stemBottomY,
        beamLevel,
        beamStartsGroup,
        beamEndsGroup,
        Object.hashAll(graceNotes),
      );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Layout d'une grace note (pour usage futur).
class GraceNoteLayout {
  const GraceNoteLayout({
    required this.position,
    required this.boundingBox,
  });

  final Offset position;
  final Rect boundingBox;
}

