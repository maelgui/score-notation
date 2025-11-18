import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/score.dart';
import '../model/duration_fraction.dart';
import '../model/measure.dart';
import '../model/note_event.dart';
import '../model/ornament.dart';
import '../model/selection_state.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/measure_editor.dart';
import '../utils/measure_helper.dart';
import '../utils/music_symbols.dart';
import '../utils/note_event_helper.dart';
import '../utils/selection_utils.dart';

/// CustomPainter chargé de dessiner la portée avec plusieurs mesures et les symboles SMuFL.
class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.score,
    this.padding = AppConstants.staffPadding,
    this.cursorPosition,
    this.selectedNotes = const {},
  });

  final Score score;
  final double padding;
  final StaffCursorPosition? cursorPosition;
  final Set<NoteSelectionReference> selectedNotes;

  // Paint objects statiques pour optimiser les performances
  static final Paint _linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = AppConstants.selectionBorderWidth
    ..strokeCap = StrokeCap.round;

  static final Paint _selectionPaint = Paint()
    ..color = Color(AppConstants.selectionColorValue)
    ..style = PaintingStyle.stroke
    ..strokeWidth = AppConstants.selectionBorderWidth;

  static final Paint _cursorPaint = Paint()
    ..color = Color(AppConstants.cursorColorValue)
    ..strokeWidth = AppConstants.cursorWidth
    ..strokeCap = StrokeCap.round;

  static const double defaultPadding = AppConstants.staffPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (score.measures.isEmpty) return;

    final double centerY = size.height / 2;
    final double availableWidth = size.width - 2 * padding;
    final double measureWidth = availableWidth / score.measures.length;
    final double minMeasureWidth =
        AppConstants.noteHeadWidth * AppConstants.minMeasureWidthFactor;

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

    Rect? selectionBounds;

    // Dessiner les barres de mesure (une seule barre entre chaque mesure) et les notes
    for (int i = 0; i < score.measures.length; i++) {
      final measure = score.measures[i];
      final double naturalWidth = _computeNaturalWidth(measure);
      final double requiredWidth = math.max(naturalWidth, minMeasureWidth);
      if (measureWidth < requiredWidth) {
        _logMeasureWidthWarning(
          measureIndex: i,
          actualWidth: measureWidth,
          requiredWidth: requiredWidth,
          naturalWidth: naturalWidth,
        );
      }
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

      // Afficher un '+' si la mesure a besoin de plus de place
      if (measureWidth < requiredWidth) {
        _drawMeasureWidthIndicator(canvas, measureEndX, centerY);
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
        final positionValue = MeasureHelper.fractionToPosition(entry.position);
        final double normalizedPosition = maxDurationValue > 0
            ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
            : 0.0;
        final double x = notesStartX + normalizedPosition * notesSpan;
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
      for (int eventIndex = 0; eventIndex < eventsWithPositions.length; eventIndex++) {
        final entry = eventsWithPositions[eventIndex];
          final positionValue = MeasureHelper.fractionToPosition(entry.position);
          final double normalizedPosition = maxDurationValue > 0
              ? (positionValue / maxDurationValue).clamp(0.0, 1.0)
              : 0.0;
          final double x = notesStartX + normalizedPosition * notesSpan;
        final reference = NoteSelectionReference(
          measureIndex: i,
          eventIndex: eventIndex,
        );
        final bool isSelected = selectedNotes.contains(reference);

        if (!entry.event.isRest) {
          final bool isBeamed = beamedNoteIndices.contains(noteIndex);
          final String symbol = isBeamed 
              ? _getNoteHeadSymbol(entry.event)
              : NoteEventHelper.getSymbol(entry.event);
          
          final double noteCenterY = _noteCenterY(entry.event, centerY);
          final Rect symbolBounds = _drawSymbol(
            canvas,
            symbol,
            Offset(x, noteCenterY),
            ornament: entry.event.ornament,
            noteEvent: entry.event,
          );
          
          if (isSelected) {
            selectionBounds = _expandSelection(selectionBounds, symbolBounds);
          }
          
          noteIndex++;
        } else {
          final String symbol = NoteEventHelper.getSymbol(entry.event);
          
          final Rect symbolBounds = _drawSymbol(
            canvas,
            symbol,
            Offset(x, centerY),
            ornament: null,
          noteEvent: entry.event,
          );

          if (isSelected) {
            selectionBounds = _expandSelection(selectionBounds, symbolBounds);
          }
        }
      }
      
      // Dessiner les beams et les hampes manuelles entre les notes groupées
      _drawBeams(canvas, notePositions, beamGroups, centerY, notesStartX, notesEndX);
    }

    final bounds = selectionBounds;
    if (bounds != null) {
      _drawSelectionBounds(canvas, bounds);
    }

    final cursor = cursorPosition;
    if (cursor != null) {
      _drawCursor(canvas, size, cursor, measureStartXs, measureEndXs);
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

  double _noteCenterY(NoteEvent event, double centerY) {
    if (event.isRest) return centerY;
    final double offset = AppConstants.noteLineOffset;
    return event.isAboveLine ? centerY - offset : centerY + offset;
  }
  
  double _oppositeHandCenterY(NoteEvent? event, double fallbackY) {
    if (event == null || event.isRest) {
      return fallbackY;
    }
    final double offset = AppConstants.noteLineOffset * 2;
    return event.isAboveLine ? fallbackY + offset : fallbackY - offset;
  }

  double _graceNoteCenterY(NoteEvent? event, double mainCenterY) {
    final double base = _oppositeHandCenterY(event, mainCenterY);
    if (event == null || event.isRest) {
      return base;
    }
    final bool mainAbove = event.isAboveLine;
    final double verticalAdjust =
        AppConstants.staffSpace * AppConstants.graceNoteVerticalOffsetFactor;
    return mainAbove ? base + verticalAdjust : base - verticalAdjust;
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

  Rect _drawSymbol(
    Canvas canvas, 
    String symbol, 
    Offset position, {
    Ornament? ornament,
    NoteEvent? noteEvent,
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

    final Rect selectionRect = Rect.fromLTWH(
      offset.dx - AppConstants.selectionPadding,
      offset.dy - AppConstants.selectionPadding,
      textPainter.width + AppConstants.selectionPadding * 2,
      textPainter.height + AppConstants.selectionPadding * 2,
    );

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
        // Grace note réduite (70%) positionnée sur la main inverse
        final TextPainter graceNotePainter = TextPainter(
          text: TextSpan(
            text: MusicSymbols.eighthNoteUp,
            style: TextStyle(
              fontFamily: 'Bravura',
              fontSize: AppConstants.symbolFontSize * AppConstants.graceNoteScale,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        final double graceCenterY = _graceNoteCenterY(noteEvent, position.dy);
        final double graceCenterX = position.dx -
            (AppConstants.noteHeadWidth * AppConstants.graceNoteHorizontalSpacingFactor);
        final Offset graceNoteOffset = Offset(
          graceCenterX - graceNotePainter.width / 2,
          graceCenterY - graceNotePainter.height / 2,
        );
        graceNotePainter.paint(canvas, graceNoteOffset);
        
        // Slash incliné ±30° attaché à la hampe
        final Paint slashPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = AppConstants.stemThickness * 0.9
          ..strokeCap = StrokeCap.round;
        final double slashLength =
            AppConstants.graceSlashLengthFactor * AppConstants.stemThickness;
        final double angleRad =
            AppConstants.graceSlashAngleDegrees * math.pi / 180;
        final Offset slashStart = Offset(
          graceNoteOffset.dx + graceNotePainter.width * 0.7,
          graceNoteOffset.dy + graceNotePainter.height * 0.25,
        );
        final Offset slashVector = Offset(
          -slashLength * math.cos(angleRad),
          slashLength * math.sin(angleRad),
        );
        canvas.drawLine(slashStart, slashStart + slashVector, slashPaint);
      } else if (ornament == Ornament.drag) {
        // Pour le drag, dessiner deux triple croches (thirty-second notes) avec une triple ligature
        // Utiliser seulement les têtes de note (sans hampe)
        final graceNoteHead = MusicSymbols.quarterNoteHead; // Tête noire standard
        
        final graceNotePainter = TextPainter(
          text: TextSpan(
            text: graceNoteHead, // Tête de note seulement
            style: TextStyle(
              fontFamily: 'Bravura',
              fontSize: AppConstants.symbolFontSize * AppConstants.graceNoteScale,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        final double graceCenterY = _graceNoteCenterY(noteEvent, position.dy);
        // Positionner deux notes de grâce juste avant la note principale, sur la main inverse
        final double baseCenterX = position.dx -
            (AppConstants.noteHeadWidth * AppConstants.graceNoteHorizontalSpacingFactor);
        final double spacing = graceNotePainter.width * 0.8;
        final double firstCenterX = baseCenterX - spacing;
        final double secondCenterX = baseCenterX;
        final double graceNoteY = graceCenterY - graceNotePainter.height / 2;
        
        final graceNoteOffset1 = Offset(
          firstCenterX - graceNotePainter.width / 2,
          graceNoteY,
        );
        final graceNoteOffset2 = Offset(
          secondCenterX - graceNotePainter.width / 2,
          graceNoteY,
        );
        
        // Dessiner les têtes de note
        graceNotePainter.paint(canvas, graceNoteOffset1);
        graceNotePainter.paint(canvas, graceNoteOffset2);
        
        // Dessiner les hampes et les beams pour les deux notes de grâce
        final Paint stemPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = AppConstants.stemThickness * AppConstants.graceNoteScale
          ..strokeCap = StrokeCap.round;
        
        final Paint beamPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = AppConstants.beamThickness * AppConstants.graceNoteScale
          ..strokeCap = StrokeCap.butt; // Extrémités nettes pour les ligatures
        
        // Placement des ligatures pour notes de grâce selon les règles SMuFL
        // Pour les hampes vers le haut, les beams sont au-dessus
        // 1. Calculer stemStart avec offsets SMuFL
        // 2. Calculer stemEnd : stemStart.y - stemLength (vers le haut)
        // 3. beam1Y = stemEnd.y
        // 4. beam_n_Y = beam1Y - (n - 1) * (beamThickness + beamSpacing)
        final double graceBeamThickness =
            AppConstants.beamThickness * AppConstants.graceNoteScale;
        final double graceBeamSpacing =
            AppConstants.beamSpacing * AppConstants.graceNoteScale;
        final double graceStemLength =
            AppConstants.stemLength * AppConstants.graceNoteStemScale;
        const int graceBeamCount = 3;
        final double beamStep = graceBeamThickness + graceBeamSpacing;
        
        // Dessiner les hampes (à droite de chaque note, vers le haut)
        // Utiliser l'offset SMuFL ajusté pour les notes de grâce
        final double graceStemOffset =
            AppConstants.stemDownXOffset.abs() * AppConstants.graceNoteScale;
        final double stem1X = firstCenterX + graceStemOffset;
        final double stem2X = secondCenterX + graceStemOffset;
        
        // Position de départ de la hampe (stemStart) avec offsets SMuFL
        final double stemStartY = graceCenterY; // Utiliser la position de la main inverse
        
        // Position du sommet de la hampe (stemEnd) : stemStart.y - stemLength (vers le haut)
        final double stemEndY = stemStartY - graceStemLength;
        
        // La première beam est placée exactement à stemEnd.y
        final double beam1Y = stemEndY;
        
        // Pour n beams, le dernier beam est à: beam1Y - (n - 1) * (beamThickness + beamSpacing)
        final double lastBeamY = beam1Y - ((graceBeamCount - 1) * beamStep);
        
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
        
        // Dessiner les beams selon la formule SMuFL
        // beam_n_Y = beam1Y - (n - 1) * (beamThickness + beamSpacing)
        final double beamStartX = stem1X;
        final double beamEndX = stem2X;
        
        for (int level = 0; level < graceBeamCount; level++) {
          final double y = beam1Y - (level * beamStep);
          canvas.drawLine(
            Offset(beamStartX, y),
            Offset(beamEndX, y),
            beamPaint,
          );
        }
      }
    }

    return selectionRect;
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

      // Placement des ligatures : on fixe le beam le plus bas à une hauteur constante,
      // puis on empile les niveaux supplémentaires vers le haut afin que les groupes
      // qui ont plus de ligatures ne descendent pas plus bas que les autres.
      final double beamThickness = AppConstants.beamThickness; // Épaisseur SMuFL (0.5 staff space)
      final double beamSpacing = AppConstants.beamSpacing; // Espace vide SMuFL (0.25 staff space)
      final double stemLength = AppConstants.stemLength; // Longueur standard (3.5 staff space)
      final double beamStep = beamThickness + beamSpacing;
      
      // Offset manuel éventuel pour affiner la hauteur des beams vers le bas.
      final double beamYOffset = AppConstants.beamYOffsetDownManual;
      
      // Hauteur du beam le plus bas (le plus éloigné de la note). Les hampes sont vers le bas,
      // donc on part du centre de la portée + la longueur de hampe.
      final double beamBaseY = centerY + stemLength + beamYOffset;

      final Paint beamPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = beamThickness
        ..strokeCap = StrokeCap.butt; // Extrémités nettes pour les ligatures
      
      // Dessiner chaque niveau de beam en remontant vers la note
      for (int level = 0; level < maxBeamCount; level++) {
        // level 0 = beam le plus bas, level 1 = beam juste au-dessus, etc.
        final double y = beamBaseY - (level * beamStep);
        
        // Trouver les notes qui ont besoin de ce niveau de beam (level+1 beams ou plus)
        // Inclure toutes les notes du groupe (les silences sont inclus mais n'ont pas de beams)
        final notesAtThisLevel = beamedNotes.where((i) => noteBeamCounts[i]! > level).toList();
        
        if (notesAtThisLevel.length < 2) continue; // Besoin d'au moins 2 notes pour un beam
        
        // Calculer les positions X de début et fin du beam
        // Le beam doit être aligné avec les hampes, pas avec le bord de la note
        // On utilise la position de la hampe (note.x + stemDownXOffset) comme référence
        final double firstStemX = notePositions[notesAtThisLevel.first].x + AppConstants.stemDownXOffset;
        final double lastStemX = notePositions[notesAtThisLevel.last].x + AppConstants.stemDownXOffset + AppConstants.stemThickness;
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
        final double stemStartX = note.x + AppConstants.stemDownXOffset + AppConstants.stemThickness /2 ;
        final double stemStartY = _noteCenterY(note.event, centerY);
        
        // Dessiner la hampe depuis stemStart jusqu'au dernier beam
        canvas.drawLine(
          Offset(stemStartX, stemStartY),
          Offset(stemStartX, beamBaseY),
          stemPaint,
        );
      }
    }
  }

  void _drawSelectionBounds(Canvas canvas, Rect bounds) {
    final rrect = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(AppConstants.selectionBorderRadius),
    );
    canvas.drawRRect(rrect, _selectionPaint);
  }

  Rect? _expandSelection(Rect? current, Rect next) {
    if (current == null) return next;
    return current.expandToInclude(next);
  }

  double _computeNaturalWidth(Measure measure) {
    // Find the smallest subdivision of the measure
    final smallestSubdivision = measure.events.reduce((a, b) => a.duration.reduce() < b.duration.reduce() ? a : b).duration.reduce();
    // Compute the equivalent number of this subdivision in the measure
    // Use division on DurationFraction, then convert to int
    final DurationFraction divisionResult = measure.totalDuration.reduce().divide(smallestSubdivision.reduce());
    final int equivalentNumberOfSubdivisions = (divisionResult.toDouble()).round();
    final double smallestSubdivisionWidth = AppConstants.noteHeadWidth * 1.5;
    return equivalentNumberOfSubdivisions * smallestSubdivisionWidth + AppConstants.spaceBeforeBarline * 2;
  }

  void _logMeasureWidthWarning({
    required int measureIndex,
    required double actualWidth,
    required double requiredWidth,
    required double naturalWidth,
  }) {
    AppLogger.warning(
      'Measure $measureIndex width ${actualWidth.toStringAsFixed(2)}px is below the '
      'required ${requiredWidth.toStringAsFixed(2)}px (natural ${naturalWidth.toStringAsFixed(2)}px, '
      'min ${ (AppConstants.noteHeadWidth * AppConstants.minMeasureWidthFactor).toStringAsFixed(2)}px). '
      'Rendering unchanged.',
    );
  }

  /// Dessine un indicateur '+' au-dessus de la fin de la mesure pour indiquer
  /// qu'elle a besoin de plus de place.
  void _drawMeasureWidthIndicator(Canvas canvas, double measureEndX, double centerY) {
    // Position du '+' : au-dessus de la fin de la mesure
    // Utiliser une taille de police plus petite que les symboles musicaux
    final double indicatorSize = AppConstants.symbolFontSize * 0.5;
    final double indicatorY = centerY - AppConstants.staffSpace * 3; // Au-dessus de la portée
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+',
        style: TextStyle(
          fontFamily: 'Arial', // Utiliser une police standard pour le '+'
          fontSize: indicatorSize,
          color: Colors.orange, // Couleur orange pour attirer l'attention
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Centrer le '+' horizontalement sur la position X de fin de mesure
    final double indicatorX = measureEndX - textPainter.width / 2;
    
    textPainter.paint(
      canvas,
      Offset(indicatorX, indicatorY - textPainter.height / 2),
    );
  }

  void _drawCursor(
    Canvas canvas,
    Size size,
    StaffCursorPosition cursor,
    List<double> measureStartXs,
    List<double> measureEndXs,
  ) {
    final int index = cursor.measureIndex;
    if (index < 0 || index >= score.measures.length) return;
    if (index >= measureStartXs.length || index >= measureEndXs.length) return;

    final measure = score.measures[index];
    final double measureStartX = measureStartXs[index];
    final double measureEndX = measureEndXs[index];
    final double notesStartX = measureStartX + AppConstants.spaceBeforeBarline;
    final double notesEndX = measureEndX - AppConstants.spaceBeforeBarline;
    final double notesSpan = notesEndX - notesStartX;
    if (notesSpan <= 0) return;

    final double normalized = SelectionUtils.positionToNormalizedX(
      position: cursor.position,
      maxDuration: measure.maxDuration,
    );
    final double cursorX = notesStartX + normalized * notesSpan;

    final double centerY = size.height / 2;
    final double extent = AppConstants.staffSpace * 2.5;
    final double top = (centerY - extent).clamp(0.0, size.height);
    final double bottom = (centerY + extent).clamp(0.0, size.height);

    canvas.drawLine(
      Offset(cursorX, top),
      Offset(cursorX, bottom),
      _cursorPaint,
    );
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
           oldDelegate.cursorPosition != cursorPosition ||
           !setEquals(oldDelegate.selectedNotes, selectedNotes);
  }
}
