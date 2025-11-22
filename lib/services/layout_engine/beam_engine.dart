import 'dart:math' as math;
import 'package:snare_notation/utils/music_symbols.dart';

import '../../model/measure.dart';
import '../../model/duration_fraction.dart';
import '../../model/note_event.dart';
import '../../utils/smufl/engraving_defaults.dart';
import 'measure_layout_result.dart';

/// Engine responsable du calcul des beams (ligatures).
///
/// Calcule :
/// - Les groupes de notes à beamer
/// - Les niveaux de beams (croche, double, triple...)
/// - Les positions Y des beams
/// - Les positions des hampes pour les notes beamed
class BeamEngine {
  BeamEngine._();

  /// Trouve les groupes de notes consécutives qui doivent être beamed.
  /// Les groupes sont limités à 1 temps maximum.
  ///
  /// Prend une liste de notes avec leurs positions et événements.
  static List<List<int>> findBeamGroups(
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    Measure measure,
  ) {
    if (notePositions.length < 2) return [];

    // Un temps = dénominateur de la signature rythmique (ex: 1/4 dans 4/4)
    final DurationFraction oneBeat = DurationFraction(
      1,
      measure.timeSignature.denominator,
    );

    final List<List<int>> beamGroups = [];
    List<int> currentGroup = [];
    DurationFraction currentGroupDuration = const DurationFraction(0, 1);

    for (int i = 0; i < notePositions.length; i++) {
      final note = notePositions[i];
      final reduced = note.event.actualDuration.reduce();

      // Vérifier si cette note doit être beamed (eighth, sixteenth, thirty-second)
      final bool shouldBeam = reduced < oneBeat;

      // Vérifier si cette note peut être beamed (eighth, sixteenth, thirty-second)
      // ou si c'est un silence qui peut être dans un groupe beamed
      final bool canBeInBeamGroup = shouldBeam;

      if (canBeInBeamGroup) {
        // Vérifier si cette note est consécutive à la dernière note du groupe actuel
        bool isConsecutive = false;
        if (currentGroup.isNotEmpty) {
          // Trouver la dernière note (pas silence) du groupe actuel
          int lastNoteIndex = currentGroup.length - 1;

          final lastNote = notePositions[lastNoteIndex];
          // Calculer la position attendue après la dernière note du groupe
          DurationFraction expectedPosition = lastNote.position;
          for (int j = lastNoteIndex; j < i; j++) {
            expectedPosition = expectedPosition.add(
              notePositions[j].event.actualDuration,
            );
          }
          isConsecutive =
              (note.position.subtract(expectedPosition).numerator.abs() < 2);
        }

        // Vérifier si on peut ajouter cette note au groupe actuel sans dépasser 1 temps
        final DurationFraction newGroupDuration = currentGroupDuration.add(
          note.event.actualDuration,
        );
        final bool exceedsOneBeat = newGroupDuration > oneBeat;

        if (currentGroup.isEmpty) {
          // Nouveau groupe (notes beamed ou silences)
          currentGroup = [i];
          currentGroupDuration = note.event.actualDuration;
        } else if (isConsecutive && !exceedsOneBeat) {
          // Ajouter au groupe actuel (notes ou silences)
          currentGroup.add(i);
          currentGroupDuration = newGroupDuration;
        } else {
          // Terminer le groupe actuel et commencer un nouveau
          if (currentGroup.length > 1) {
            beamGroups.add(List.from(currentGroup));
          }
          currentGroup = [i];
          currentGroupDuration = note.event.actualDuration;
        }
      } else {
        // Note qui ne doit pas être beamed, terminer le groupe actuel
        if (currentGroup.length > 1) {
          beamGroups.add(List.from(currentGroup));
        }
        currentGroup = [];
        currentGroupDuration = const DurationFraction(0, 1);
      }
    }

    // Ajouter le dernier groupe s'il existe
    if (currentGroup.length > 1) {
      beamGroups.add(currentGroup);
    }

    return beamGroups;
  }

  /// Calcule les segments de beams à partir des groupes.
  ///
  /// Retourne une liste de LayoutedBeamSegment avec les positions calculées.
  ///
  /// Prend une liste de notes avec leurs positions et événements pour calculer
  /// les positions X des beams.
  static List<LayoutedBeamSegment> computeBeamSegments(
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    List<List<int>> beamGroups,
    double staffY,
  ) {
    final List<LayoutedBeamSegment> segments = [];

    if (beamGroups.isEmpty) return segments;

    // Calculer les nombres de beams pour chaque note
    final Map<int, int> noteBeamCounts = computeBeamCounts(
      notePositions,
      beamGroups,
    );

    // Placement des ligatures selon SMuFL (même logique que l'ancien code)
    final double beamThickness = EngravingDefaults.beamThickness;
    final double beamSpacing = EngravingDefaults.beamSpacing;
    final double stemLength = EngravingDefaults.stemLength;
    final double beamStep = beamThickness + beamSpacing;

    // Hauteur du beam le plus bas (le plus éloigné de la note)
    // Les hampes sont vers le bas, donc on part du centre de la portée + la longueur de hampe
    // Note: beamYOffset manuel n'existe plus, donc on utilise juste staffY + stemLength
    final double beamBaseY = staffY + stemLength;

    for (final group in beamGroups) {
      if (group.length < 2) continue;

      // Déterminer le nombre maximum de beams selon les durées
      int maxBeamCount = 1;
      for (final noteIndex in group) {
        if (noteIndex >= notePositions.length) continue;
        final beamCount = noteBeamCounts[noteIndex] ?? 1;
        maxBeamCount = math.max(maxBeamCount, beamCount);
      }

      // Créer un segment pour chaque niveau de beam
      for (int level = 0; level < maxBeamCount; level++) {
        // Position Y du beam pour ce niveau
        final double y = beamBaseY - (level * beamStep);

        // Créer des segments pour notes consécutives ayant ce niveau de beam
        List<int> currentSegment = [];

        for (int i = 0; i < group.length; i++) {
          final noteIndex = group[i];
          final beamCount = noteBeamCounts[noteIndex] ?? 0;

          if (beamCount > level) {
            currentSegment.add(noteIndex);
          } else {
            // Cette note n'a pas ce niveau de beam, finaliser le segment
            if (currentSegment.length >= 2) {
              _addBeamSegment(
                segments,
                notePositions,
                currentSegment,
                level,
                y,
              );
            } else if (currentSegment.length == 1) {
              // Note isolée : créer un beam coupé
              _addPartialBeam(
                segments,
                notePositions,
                group,
                currentSegment[0],
                level,
                y,
              );
            }
            currentSegment = [];
          }
        }

        // Finaliser le dernier segment
        if (currentSegment.length >= 2) {
          _addBeamSegment(segments, notePositions, currentSegment, level, y);
        } else if (currentSegment.length == 1) {
          // Note isolée : créer un beam coupé
          _addPartialBeam(
            segments,
            notePositions,
            group,
            currentSegment[0],
            level,
            y,
          );
        }
      }
    }

    return segments;
  }

  /// Calcule le nombre de beams pour chaque note.
  /// Retourne une Map<noteIndex, beamCount>
  static Map<int, int> computeBeamCounts(
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    List<List<int>> beamGroups,
  ) {
    final Map<int, int> beamCounts = {};

    for (final group in beamGroups) {
      for (final noteIndex in group) {
        if (noteIndex >= notePositions.length) continue;
        final note = notePositions[noteIndex];
        final reduced = note.event.writenDuration;

        int beamCount = 1;
        if (reduced == NoteDuration.sixteenth) {
          beamCount = 2;
        } else if (reduced == NoteDuration.thirtySecond) {
          beamCount = 3;
        }

        beamCounts[noteIndex] = beamCount;
      }
    }

    return beamCounts;
  }

  /// Ajoute un segment de beam aux résultats.
  static void _addBeamSegment(
    List<LayoutedBeamSegment> segments,
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    List<int> noteIndices,
    int level,
    double y,
  ) {
    final double firstStemX =
        notePositions[noteIndices.first].x + EngravingDefaults.stemDownXOffset;
    final double lastStemX =
        notePositions[noteIndices.last].x +
        EngravingDefaults.stemDownXOffset +
        EngravingDefaults.stemThickness;

    // Détecter si ce groupe de notes forme un tuplet
    int? tupletNumber = _detectTupletNumber(notePositions, noteIndices);

    segments.add(
      LayoutedBeamSegment(
        level: level,
        startX: firstStemX,
        endX: lastStemX,
        y: y,
        noteIndices: noteIndices,
        tupletNumber: tupletNumber,
      ),
    );
  }

  /// Ajoute un beam coupé (partial beam) pour une note isolée.
  static void _addPartialBeam(
    List<LayoutedBeamSegment> segments,
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    List<int> group,
    int noteIndex,
    int level,
    double y,
  ) {
    final double stemX =
        notePositions[noteIndex].x + EngravingDefaults.stemDownXOffset;
    final double beamLength =
        EngravingDefaults.beamThickness * 3; // Longueur du beam coupé

    // Déterminer les positions du beam coupé
    final int positionInGroup = group.indexOf(noteIndex);
    final bool isFirst = positionInGroup == 0;
    final bool isLast = positionInGroup == group.length - 1;

    double startX, endX;

    if (isFirst) {
      // Première note : beam vers la droite
      startX = stemX;
      endX = stemX + beamLength;
    } else if (isLast) {
      // Dernière note : beam vers la gauche
      startX = stemX - beamLength;
      endX = stemX + EngravingDefaults.stemThickness;
    } else {
      // Note au milieu : beam vers la note suivante par défaut
      startX = stemX;
      endX = stemX + beamLength;
    }

    // Détecter si cette note fait partie d'un tuplet
    int? tupletNumber = _detectTupletNumber(notePositions, [noteIndex]);

    segments.add(
      LayoutedBeamSegment(
        level: level,
        startX: startX,
        endX: endX,
        y: y,
        noteIndices: [noteIndex],
        tupletNumber: tupletNumber,
      ),
    );
  }

  /// Détecte si un groupe de notes forme un tuplet et retourne le numéro.
  /// Retourne null si ce n'est pas un tuplet ou si les notes n'ont pas toutes le même tuplet.
  static int? _detectTupletNumber(
    List<({double x, NoteEvent event, DurationFraction position})>
    notePositions,
    List<int> noteIndices,
  ) {
    if (noteIndices.isEmpty) return null;

    // Vérifier que toutes les notes du groupe ont le même tuplet
    int? tupletNumber;
    bool hasTuplet = false;

    for (final noteIndex in noteIndices) {
      if (noteIndex >= notePositions.length) continue;

      final note = notePositions[noteIndex];
      final tuplet = note.event.tuplet;

      if (tuplet == null) {
        // Si une note n'a pas de tuplet, le groupe n'est pas un tuplet
        return null; // On continue pour voir s'il y a d'autres notes avec tuplet
      }

      hasTuplet = true;
      if (tupletNumber == null) {
        tupletNumber = tuplet.actualNotes;
      } else if (tupletNumber != tuplet.actualNotes) {
        // Si les notes ont des tuplets différents, pas de numéro unique
        return null;
      }
    }
    return hasTuplet ? tupletNumber : null;
  }
}
