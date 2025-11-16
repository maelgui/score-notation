import 'package:flutter/material.dart';

import '../model/score.dart';
import '../model/duration_fraction.dart';
import '../model/measure.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../utils/constants.dart';
import '../utils/measure_editor.dart';
import '../utils/measure_helper.dart';
import '../utils/music_symbols.dart';
import '../utils/note_event_helper.dart';

/// CustomPainter chargé de dessiner la portée avec plusieurs mesures et les symboles SMuFL.
class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.score,
    this.padding = AppConstants.staffPadding,
    this.selectedMeasureIndex,
    this.selectedPosition,
  });

  final Score score;
  final double padding;
  final int? selectedMeasureIndex;
  final DurationFraction? selectedPosition;

  // Paint objects statiques pour optimiser les performances
  static final Paint _linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = AppConstants.selectionBorderWidth
    ..strokeCap = StrokeCap.round;

  static final Paint _selectionPaint = Paint()
    ..color = Color(AppConstants.selectionColorValue)
    ..style = PaintingStyle.stroke
    ..strokeWidth = AppConstants.selectionBorderWidth;

  static const double defaultPadding = AppConstants.staffPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (score.measures.isEmpty) return;

    final double centerY = size.height / 2;
    final double availableWidth = size.width - 2 * padding;
    final double measureWidth = availableWidth / score.measures.length;

    // Calculer les positions X de chaque mesure
    final List<double> measureStartXs = [];
    final List<double> measureEndXs = [];
    double currentX = padding;
    
    for (int i = 0; i < score.measures.length; i++) {
      final double measureStartX = currentX;
      final double measureEndX = currentX + measureWidth - AppConstants.barSpacing;
      measureStartXs.add(measureStartX);
      measureEndXs.add(measureEndX);
      currentX = measureEndX + AppConstants.barSpacing;
    }
    
    // Dessiner la ligne de portée continue sur toute la largeur
    final double staffStartX = measureStartXs.first;
    final double staffEndX = measureEndXs.last;
    canvas.drawLine(
      Offset(staffStartX, centerY),
      Offset(staffEndX, centerY),
      _linePaint,
    );

    // Dessiner une barre simple au début de la partition (symbole SMuFL E030)
    final double firstMeasureStartX = measureStartXs.first;
    _drawBarlineSymbol(canvas, MusicSymbols.barlineSingle, firstMeasureStartX, centerY);

    // Dessiner les barres de mesure (une seule barre entre chaque mesure) et les notes
    for (int i = 0; i < score.measures.length; i++) {
      final measure = score.measures[i];
      final double measureStartX = measureStartXs[i];
      final double measureEndX = measureEndXs[i];

      // Dessiner la signature rythmique uniquement pour la première mesure
      if (i == 0) {
        _drawTimeSignature(
          canvas,
          centerY,
          measureStartX,
          measure.timeSignature.numerator,
          measure.timeSignature.denominator,
        );
      }

      // Dessiner une barre à la fin de chaque mesure (sauf la dernière) - symbole SMuFL E030
      if (i < score.measures.length - 1) {
        _drawBarlineSymbol(canvas, MusicSymbols.barlineSingle, measureEndX, centerY);
      }

      // Dessiner les notes de cette mesure
      // Zone disponible pour les notes (avec espacement SMuFL avant les barres)
      final double notesStartX = measureStartX + AppConstants.spaceBeforeBarline;
      final double notesEndX = measureEndX - AppConstants.spaceBeforeBarline;
      final double notesSpan = notesEndX - notesStartX;
      final maxDuration = measure.maxDuration;
      final maxDurationValue = MeasureHelper.fractionToPosition(maxDuration);

      // Extraire les événements avec leurs positions
      final eventsWithPositions = MeasureEditor.extractEventsWithPositions(measure);
      
      // Stocker les positions X des notes pour dessiner les beams
      final List<({double x, NoteEvent event, DurationFraction position})> notePositions = [];
      
      for (final entry in eventsWithPositions) {
        // Convertir la position temporelle (en noires) en position X
        final positionValue = MeasureHelper.fractionToPosition(entry.position);
        final double normalizedPosition = maxDurationValue > 0
            ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
            : 0.0;
        final double x = notesStartX + normalizedPosition * notesSpan;
        
        // Stocker la position pour les beams (seulement les notes, pas les silences)
        notePositions.add((x: x, event: entry.event, position: entry.position));
      }
      
      // Trouver les groupes de notes beamed (limités à 1 temps maximum)
      final beamGroups = _findBeamGroups(notePositions, measure);
      final Set<int> beamedNoteIndices = {};
      for (final group in beamGroups) {
        beamedNoteIndices.addAll(group);
      }
      
      // Dessiner les notes
      int noteIndex = 0;
      for (final entry in eventsWithPositions) {
        if (!entry.event.isRest) {
          // Convertir la position temporelle (en noires) en position X
          final positionValue = MeasureHelper.fractionToPosition(entry.position);
          final double normalizedPosition = maxDurationValue > 0
              ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
              : 0.0;
          final double x = notesStartX + normalizedPosition * notesSpan;
          
          // Vérifier si cette note est sélectionnée
          final isSelected = selectedMeasureIndex == i && 
              selectedPosition != null &&
              entry.position.reduce() == selectedPosition!.reduce();
          
          // Si la note fait partie d'un groupe beamed, utiliser seulement la tête de note
          // (mais seulement si c'est une note, pas un silence)
          final bool isBeamed = beamedNoteIndices.contains(noteIndex) && !entry.event.isRest;
          final String symbol = isBeamed 
              ? _getNoteHeadSymbol(entry.event)
              : NoteEventHelper.getSymbol(entry.event);
          
          // Dessiner la note avec indication d'ornement si présent
          _drawSymbol(
            canvas, 
            symbol, 
            Offset(x, centerY), 
            isSelected: isSelected,
            ornament: entry.event.ornament,
          );
          
          noteIndex++;
        } else {
          // Pour les silences, dessiner normalement
          final positionValue = MeasureHelper.fractionToPosition(entry.position);
          final double normalizedPosition = maxDurationValue > 0
              ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
              : 0.0;
          final double x = notesStartX + normalizedPosition * notesSpan;
          final String symbol = NoteEventHelper.getSymbol(entry.event);
          
          final isSelected = selectedMeasureIndex == i && 
              selectedPosition != null &&
              entry.position.reduce() == selectedPosition!.reduce();
          
          _drawSymbol(
            canvas, 
            symbol, 
            Offset(x, centerY), 
            isSelected: isSelected,
            ornament: null,
          );
        }
      }
      
      // Dessiner les beams et les hampes manuelles entre les notes groupées
      _drawBeams(canvas, notePositions, beamGroups, centerY, notesStartX, notesEndX);
    }

    // Dessiner la double barre finale à la fin de la partition (symbole SMuFL E032)
    final double lastMeasureEndX = measureEndXs.last;
    _drawBarlineSymbol(
      canvas,
      MusicSymbols.barlineFinal,
      lastMeasureEndX,
      centerY,
    );
  }

  /// Dessine un symbole de barre SMuFL (E030, E032, etc.)
  void _drawBarlineSymbol(
    Canvas canvas,
    String symbol,
    double x,
    double centerY,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: AppConstants.barLineHeight,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double glyphHeightPx = AppConstants.barLineHeight; // 4 staff spaces
    final double baselineDistance =
        textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double baselineY = centerY + glyphHeightPx / 2;
    final double offsetY = baselineY - baselineDistance;

    textPainter.paint(canvas, Offset(x, offsetY));
  }

  /// Retourne le symbole de tête de note (sans hampe) selon la durée.
  String _getNoteHeadSymbol(NoteEvent event) {
    final reduced = event.duration.reduce();
    if (reduced == DurationFraction.whole) {
      return MusicSymbols.wholeNote; // Pas de hampe
    } else if (reduced == DurationFraction.half) {
      return '\uE0A3'; // NoteheadHalf (blanche)
    } else {
      // Pour toutes les autres durées, utiliser la tête noire
      return MusicSymbols.quarterNoteHead; // NoteheadBlack
    }
  }

  void _drawSymbol(
    Canvas canvas, 
    String symbol, 
    Offset position, {
    bool isSelected = false,
    Ornament? ornament,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: const TextStyle(
          fontFamily: 'Bravura',
          fontSize: AppConstants.symbolFontSize,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);

    // Si un ornement est présent, dessiner le symbole approprié
    if (ornament != null) {
      if (ornament == Ornament.roll) {
        // Pour le roulement, utiliser le symbole SMuFL tremolo3 (3 barres)
        final tremoloPainter = TextPainter(
          text: TextSpan(
            text: MusicSymbols.roll,
            style: TextStyle(
              fontFamily: 'Bravura',
              fontSize: AppConstants.symbolFontSize * 0.9,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        // Positionner le tremolo à droite de la note, centré verticalement sur la hampe
        // La hampe est maintenant vers le bas, donc on positionne le tremolo sur la hampe
        final tremoloOffset = Offset(
          offset.dx + textPainter.width / 2 - 2, // Déplacer vers la gauche
          offset.dy + textPainter.height * 0.2, // Remonter le tremolo
        );
        tremoloPainter.paint(canvas, tremoloOffset);
      } else if (ornament == Ornament.flam) {
        // Pour le flam, dessiner une croche (eighth note) de grâce juste avant la note principale
        // La note de grâce doit toujours être une croche avec hampe vers le haut, sur la même ligne
        final graceNoteSymbol = MusicSymbols.eighthNoteUp; // Toujours une croche
        
        final graceNotePainter = TextPainter(
          text: TextSpan(
            text: graceNoteSymbol, // Croche avec hampe vers le haut
            style: TextStyle(
              fontFamily: 'Bravura',
              fontSize: AppConstants.symbolFontSize * 0.6, // Plus petite
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        // Positionner la note de grâce juste avant la note principale, sur la même ligne
        final graceNoteOffset = Offset(
          position.dx - graceNotePainter.width / 2 - 12, // À gauche de la note principale
          position.dy - graceNotePainter.height / 2, // Même hauteur que la note principale (sur la ligne)
        );
        graceNotePainter.paint(canvas, graceNoteOffset);
      } else if (ornament == Ornament.drag) {
        // Pour le drag, dessiner deux double croches (sixteenth notes) avec une double ligature (2 beams)
        // Utiliser seulement les têtes de note (sans hampe)
        final graceNoteHead = MusicSymbols.quarterNoteHead; // Tête noire pour double croche
        
        final graceNotePainter = TextPainter(
          text: TextSpan(
            text: graceNoteHead, // Tête de note seulement
            style: TextStyle(
              fontFamily: 'Bravura',
              fontSize: AppConstants.symbolFontSize * 0.6, // Plus petite
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        // Positionner deux notes de grâce juste avant la note principale, sur la même ligne
        final double graceNote1X = position.dx - graceNotePainter.width / 2 - 18; // Première note plus à gauche
        final double graceNote2X = position.dx - graceNotePainter.width / 2 - 8; // Deuxième note un peu à droite
        final double graceNoteY = position.dy - graceNotePainter.height / 2; // Même hauteur que la note principale
        
        final graceNoteOffset1 = Offset(graceNote1X, graceNoteY);
        final graceNoteOffset2 = Offset(graceNote2X, graceNoteY);
        
        // Dessiner les têtes de note
        graceNotePainter.paint(canvas, graceNoteOffset1);
        graceNotePainter.paint(canvas, graceNoteOffset2);
        
        // Dessiner les hampes et les beams pour les deux notes de grâce
        final Paint stemPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = AppConstants.stemThickness * 0.6 // Plus fin pour les notes de grâce (60% de la taille normale)
          ..strokeCap = StrokeCap.round;
        
        final Paint beamPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = AppConstants.beamThickness * 0.6 // Plus fin pour les notes de grâce (60% de la taille normale)
          ..strokeCap = StrokeCap.butt; // Extrémités nettes pour les ligatures
        
        // Placement des ligatures pour notes de grâce selon les règles SMuFL
        // Pour les hampes vers le haut, les beams sont au-dessus
        // 1. Calculer stemStart avec offsets SMuFL
        // 2. Calculer stemEnd : stemStart.y - stemLength (vers le haut)
        // 3. beam1Y = stemEnd.y
        // 4. beam_n_Y = beam1Y - (n - 1) * (beamThickness + beamSpacing)
        final double graceBeamThickness = AppConstants.beamThickness * 0.6; // 60% de la taille normale
        final double graceBeamSpacing = AppConstants.beamSpacing * 0.6; // 60% de la taille normale
        final double graceStemLength = AppConstants.stemLength * 0.6; // 60% de la taille normale
        
        // Dessiner les hampes (à gauche de chaque note, vers le haut)
        // Utiliser l'offset SMuFL ajusté pour les notes de grâce
        final double graceStemOffset = AppConstants.stemDownXOffset * 0.6; // 60% de l'offset normal
        final double stem1X = graceNote1X + graceNotePainter.width / 2 + graceStemOffset;
        final double stem2X = graceNote2X + graceNotePainter.width / 2 + graceStemOffset;
        
        // Position de départ de la hampe (stemStart) avec offsets SMuFL
        final double stemStartY = position.dy; // La tête de note est au niveau de la note principale
        
        // Position du sommet de la hampe (stemEnd) : stemStart.y - stemLength (vers le haut)
        final double stemEndY = stemStartY - graceStemLength;
        
        // La première beam est placée exactement à stemEnd.y
        final double beam1Y = stemEndY;
        
        // Pour 2 beams, le dernier beam est à: beam1Y - (2 - 1) * (beamThickness + beamSpacing)
        final double lastBeamY = beam1Y - (1 * (graceBeamThickness + graceBeamSpacing));
        
        canvas.drawLine(
          Offset(stem1X, stemStartY),
          Offset(stem1X, lastBeamY),
          stemPaint,
        );
        canvas.drawLine(
          Offset(stem2X, stemStartY),
          Offset(stem2X, lastBeamY),
          stemPaint,
        );
        
        // Dessiner les 2 beams (double ligature) selon la formule SMuFL
        // beam_n_Y = beam1Y - (n - 1) * (beamThickness + beamSpacing)
        final double beamStartX = stem1X;
        final double beamEndX = stem2X;
        
        for (int level = 0; level < 2; level++) {
          // Formule SMuFL: beam1Y - level * (beamThickness + beamSpacing)
          final double y = beam1Y - (level * (graceBeamThickness + graceBeamSpacing));
          canvas.drawLine(
            Offset(beamStartX, y),
            Offset(beamEndX, y),
            beamPaint,
          );
        }
      }
    }

    // Dessiner un contour autour de la note si elle est sélectionnée
    if (isSelected) {
      final rect = Rect.fromLTWH(
        offset.dx - AppConstants.selectionPadding,
        offset.dy - AppConstants.selectionPadding,
        textPainter.width + AppConstants.selectionPadding * 2,
        textPainter.height + AppConstants.selectionPadding * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppConstants.selectionBorderRadius)),
        _selectionPaint,
      );
    }
  }

  /// Trouve les groupes de notes consécutives qui doivent être beamed.
  /// Les groupes sont limités à 1 temps maximum.
  List<List<int>> _findBeamGroups(
    List<({double x, NoteEvent event, DurationFraction position})> notePositions,
    Measure measure,
  ) {
    if (notePositions.length < 2) return [];

    // Un temps = dénominateur de la signature rythmique (ex: 1/4 dans 4/4)
    final DurationFraction oneBeat = DurationFraction(1, measure.timeSignature.denominator);

    final List<List<int>> beamGroups = [];
    List<int> currentGroup = [];
    DurationFraction currentGroupDuration = const DurationFraction(0, 1);

    for (int i = 0; i < notePositions.length; i++) {
      final note = notePositions[i];
      final reduced = note.event.duration.reduce();
      
      // Vérifier si cette note doit être beamed (eighth, sixteenth, thirty-second)
      final bool shouldBeam = reduced == DurationFraction.eighth ||
                              reduced == DurationFraction.sixteenth ||
                              reduced == DurationFraction.thirtySecond;

      // Vérifier si cette note peut être beamed (eighth, sixteenth, thirty-second)
      // ou si c'est un silence qui peut être dans un groupe beamed
      final bool canBeInBeamGroup = shouldBeam || note.event.isRest;

      if (canBeInBeamGroup) {
        // Vérifier si cette note est consécutive à la dernière note du groupe actuel
        bool isConsecutive = false;
        if (currentGroup.isNotEmpty) {
          // Trouver la dernière note (pas silence) du groupe actuel
          int? lastNoteIndex;
          for (int j = currentGroup.length - 1; j >= 0; j--) {
            final idx = currentGroup[j];
            if (!notePositions[idx].event.isRest) {
              lastNoteIndex = idx;
              break;
            }
          }
          
          if (lastNoteIndex != null) {
            final lastNote = notePositions[lastNoteIndex];
            // Calculer la position attendue après la dernière note du groupe
            DurationFraction expectedPosition = lastNote.position;
            for (int j = lastNoteIndex; j < i; j++) {
              expectedPosition = expectedPosition.add(notePositions[j].event.duration);
            }
            isConsecutive = (note.position.subtract(expectedPosition).numerator.abs() < 2);
          }
        }

        // Vérifier si on peut ajouter cette note au groupe actuel sans dépasser 1 temps
        final DurationFraction newGroupDuration = currentGroupDuration.add(note.event.duration);
        final bool exceedsOneBeat = newGroupDuration > oneBeat;

        if (currentGroup.isEmpty) {
          // Nouveau groupe (notes beamed ou silences)
          currentGroup = [i];
          currentGroupDuration = note.event.duration;
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
          currentGroupDuration = note.event.duration;
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

  /// Dessine les barres de ligature (beams) entre les notes groupées et les hampes manuelles.
  /// 
  /// Les beams sont dessinés pour les notes de durée eighth, sixteenth, et thirty-second
  /// qui sont consécutives (sans silences entre elles).
  void _drawBeams(
    Canvas canvas,
    List<({double x, NoteEvent event, DurationFraction position})> notePositions,
    List<List<int>> beamGroups,
    double centerY,
    double notesStartX,
    double notesEndX,
  ) {
    if (beamGroups.isEmpty) return;

    // Dessiner les beams pour chaque groupe
    for (final group in beamGroups) {
      if (group.length < 2) continue;

      // Utiliser toutes les notes du groupe (y compris les silences pour le calcul des beams)
      final beamedNotes = group; // Inclure tous les événements
      if (beamedNotes.length < 2) continue;

      // Déterminer le nombre maximum de beams selon les durées (notes et silences)
      int maxBeamCount = 1;
      for (final noteIndex in beamedNotes) {
        final note = notePositions[noteIndex];
        final reduced = note.event.duration.reduce();
        int noteBeamCount = 1;
        if (reduced == DurationFraction.sixteenth) {
          noteBeamCount = 2;
        } else if (reduced == DurationFraction.thirtySecond) {
          noteBeamCount = 3;
        }
        if (noteBeamCount > maxBeamCount) {
          maxBeamCount = noteBeamCount;
        }
      }
      
      // Déterminer quelles notes/silences ont besoin de combien de beams
      final Map<int, int> noteBeamCounts = {};
      for (final noteIndex in beamedNotes) {
        final note = notePositions[noteIndex];
        final reduced = note.event.duration.reduce();
        if (reduced == DurationFraction.sixteenth) {
          noteBeamCounts[noteIndex] = 2;
        } else if (reduced == DurationFraction.thirtySecond) {
          noteBeamCounts[noteIndex] = 3;
        } else {
          noteBeamCounts[noteIndex] = 1;
        }
      }

      // Placement des ligatures selon les règles SMuFL
      // 1. Calculer la position de départ de la hampe (stemStart) avec les offsets SMuFL
      // 2. Calculer la position du sommet de la hampe (stemEnd) : stemStart.y + stemLength
      // 3. La première beam est placée exactement à stemEnd.y
      // 4. Les beams suivants : beam_n_Y = beam1Y + (n - 1) * (beamThickness + beamSpacing)
      
      final double beamThickness = AppConstants.beamThickness; // Épaisseur SMuFL (0.5 staff space)
      final double beamSpacing = AppConstants.beamSpacing; // Espace vide SMuFL (0.25 staff space)
      final double stemLength = AppConstants.stemLength; // Longueur standard (3.5 staff space)
      
      // Position de départ de la hampe (stemStart) avec offsets SMuFL
      // Toutes les notes du groupe ont la même position Y (sur la ligne)
      final double stemStartY = centerY; // La tête de note est sur la ligne
      
      // Position du sommet de la hampe (stemEnd) : stemStart.y + stemLength (vers le bas)
      final double stemEndY = stemStartY + stemLength;
      
      // La première beam est placée exactement à stemEnd.y
      final double beam1Y = stemEndY;

      final Paint beamPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = beamThickness
        ..strokeCap = StrokeCap.butt; // Extrémités nettes pour les ligatures
      
      // Dessiner chaque niveau de beam selon la formule SMuFL
      // beam_n_Y = beam1Y + (n - 1) * (beamThickness + beamSpacing)
      for (int level = 0; level < maxBeamCount; level++) {
        // level 0 = Beam #1, level 1 = Beam #2, etc.
        // Formule SMuFL: beam1Y + level * (beamThickness + beamSpacing)
        final double y = beam1Y + (level * (beamThickness + beamSpacing));
        
        // Trouver les notes qui ont besoin de ce niveau de beam (level+1 beams ou plus)
        // Inclure toutes les notes du groupe (les silences sont inclus mais n'ont pas de beams)
        final notesAtThisLevel = beamedNotes.where((i) => noteBeamCounts[i]! > level).toList();
        
        if (notesAtThisLevel.length < 2) continue; // Besoin d'au moins 2 notes pour un beam
        
        // Calculer les positions X de début et fin du beam
        // Le beam doit être aligné avec les hampes, pas avec le bord de la note
        // On utilise la position de la hampe (note.x + stemDownXOffset) comme référence
        final double firstStemX = notePositions[notesAtThisLevel.first].x + AppConstants.stemDownXOffset;
        final double lastStemX = notePositions[notesAtThisLevel.last].x + AppConstants.stemDownXOffset;
        final double startX = firstStemX;
        final double endX = lastStemX;
        
        // Dessiner le beam
        canvas.drawLine(
          Offset(startX, y),
          Offset(endX, y),
          beamPaint,
        );
      }
      
      // Dessiner les hampes manuelles pour chaque note beamed (pas les silences)
      final Paint stemPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = AppConstants.stemThickness // Épaisseur SMuFL pour les hampes
        ..strokeCap = StrokeCap.round;
      
      for (final noteIndex in beamedNotes) {
        final note = notePositions[noteIndex];
        // Ne dessiner les hampes que pour les notes, pas les silences
        if (note.event.isRest) continue;
        
        // Position de départ de la hampe (stemStart) avec offsets SMuFL
        final double stemStartX = note.x + AppConstants.stemDownXOffset;
        final double stemStartY = centerY; // La tête de note est sur la ligne
        
        // Pour cette note, calculer où se termine la hampe (au dernier beam)
        final int noteBeamCount = noteBeamCounts[noteIndex] ?? 1;
        // Le dernier beam est à: beam1Y + (noteBeamCount - 1) * (beamThickness + beamSpacing)
        final double lastBeamY = beam1Y + ((noteBeamCount - 1) * (beamThickness + beamSpacing));
        
        // Dessiner la hampe depuis stemStart jusqu'au dernier beam
        canvas.drawLine(
          Offset(stemStartX, stemStartY),
          Offset(stemStartX, lastBeamY),
          stemPaint,
        );
      }
    }
  }

  void _drawTimeSignature(
    Canvas canvas,
    double centerY,
    double startX,
    int numerator,
    int denominator,
  ) {
    // Placement selon les règles SMuFL pour signatures rythmiques
    // 1. Convertir les nombres en listes de chiffres
    final topDigits = _numberToDigits(numerator);
    final bottomDigits = _numberToDigits(denominator);
    
    // 2. Configuration selon SMuFL
    final double fontSize = AppConstants.symbolFontSize; // Taille standard de police musicale
    final double timeSigSpacing = fontSize * 0.15; // Espacement SMuFL recommandé
    
    // 3. Créer les TextPainter pour chaque chiffre et calculer les largeurs
    final topPainters = <TextPainter>[];
    final bottomPainters = <TextPainter>[];
    
    for (final digit in topDigits) {
      final glyph = MusicSymbols.timeSigDigit(digit);
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontFamily: 'Bravura',
            fontSize: fontSize,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      topPainters.add(painter);
    }
    
    for (final digit in bottomDigits) {
      final glyph = MusicSymbols.timeSigDigit(digit);
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontFamily: 'Bravura',
            fontSize: fontSize,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bottomPainters.add(painter);
    }
    
    // 4. Calculer les largeurs totales des groupes
    double topGroupWidth = 0.0;
    for (int i = 0; i < topPainters.length; i++) {
      topGroupWidth += topPainters[i].width;
      if (i < topPainters.length - 1) {
        topGroupWidth += timeSigSpacing;
      }
    }
    
    double bottomGroupWidth = 0.0;
    for (int i = 0; i < bottomPainters.length; i++) {
      bottomGroupWidth += bottomPainters[i].width;
      if (i < bottomPainters.length - 1) {
        bottomGroupWidth += timeSigSpacing;
      }
    }
    
    // 5. Alignement centré : utiliser la largeur maximale
    final double maxWidth = topGroupWidth > bottomGroupWidth ? topGroupWidth : bottomGroupWidth;
    
    // 6. Position X de base (juste avant la mesure)
    final double baseX = (startX - maxWidth - AppConstants.timeSignatureSpacing).clamp(0.0, double.infinity);
    
    // 7. Positions Y selon SMuFL
    // Chiffre du haut : y = staffY - fontSize * 0.7
    // Chiffre du bas : y = staffY + fontSize * 0.7
    final double topY = centerY - fontSize * 0.7;
    final double bottomY = centerY + fontSize * 0.7;
    
    // 8. Dessiner les chiffres du haut (alignés centrés)
    double currentX = baseX + (maxWidth - topGroupWidth) / 2;
    for (int i = 0; i < topPainters.length; i++) {
      final painter = topPainters[i];
      painter.paint(
        canvas,
        Offset(currentX, topY - painter.height / 2),
      );
      currentX += painter.width;
      if (i < topPainters.length - 1) {
        currentX += timeSigSpacing;
      }
    }
    
    // 9. Dessiner les chiffres du bas (alignés centrés)
    currentX = baseX + (maxWidth - bottomGroupWidth) / 2;
    for (int i = 0; i < bottomPainters.length; i++) {
      final painter = bottomPainters[i];
      painter.paint(
        canvas,
        Offset(currentX, bottomY - painter.height / 2),
      );
      currentX += painter.width;
      if (i < bottomPainters.length - 1) {
        currentX += timeSigSpacing;
      }
    }
  }
  
  /// Convertit un nombre en liste de chiffres (ex: 12 → [1, 2])
  List<int> _numberToDigits(int number) {
    if (number == 0) return [0];
    final digits = <int>[];
    int n = number;
    while (n > 0) {
      digits.insert(0, n % 10);
      n ~/= 10;
    }
    return digits;
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.score != score || 
           oldDelegate.padding != padding ||
           oldDelegate.selectedMeasureIndex != selectedMeasureIndex ||
           oldDelegate.selectedPosition != selectedPosition;
  }
}
