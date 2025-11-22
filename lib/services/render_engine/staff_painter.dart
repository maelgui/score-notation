import 'package:flutter/material.dart';
import '../../model/score.dart';
import '../../model/selection_state.dart';
import '../../utils/constants.dart';
import '../../utils/music_symbols.dart';
import '../../utils/note_event_helper.dart';
import '../../utils/selection_utils.dart';
import '../../utils/smufl/engraving_defaults.dart';
import '../layout_engine/measure_layout_result.dart';
import '../layout_engine/page_layout_result.dart';
import '../layout_engine/staff_layout_result.dart';
import 'beam_painter.dart';
import 'glyph_painter.dart';

/// Painter responsable du dessin de la portée.
///
/// Reçoit un PageLayoutResult pré-calculé et ne fait que du dessin.
/// Aucune logique de calcul ici.
class StaffPainter extends CustomPainter {
  const StaffPainter({
    required this.score,
    required this.pageLayoutResult,
    this.padding = 24.0,
    this.cursorPosition,
    this.selectedNotes = const {},
  });

  final Score score;
  final PageLayoutResult pageLayoutResult;
  final double padding;
  final StaffCursorPosition? cursorPosition;
  final Set<NoteSelectionReference> selectedNotes;

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

  @override
  void paint(Canvas canvas, Size size) {
    if (score.measures.isEmpty || pageLayoutResult.systems.isEmpty) {
      return;
    }

    Rect? selectionBounds;
    final Map<int, Rect> allMeasureBounds = {};

    // Dessiner chaque système
    for (final system in pageLayoutResult.systems) {
      final double staffY = system.staffY;

      // Dessiner la ligne de portée
      final double staffEndX = system.origin.dx + system.width;
      canvas.drawLine(
        Offset(system.origin.dx, staffY),
        Offset(staffEndX, staffY),
        _linePaint,
      );

      // Dessiner les mesures de ce système
      for (int i = 0; i < system.measures.length; i++) {
        final measureLayout = system.measures[i];
        final measure = measureLayout.measureModel;

        // Stocker le bounding box avec l'index de la mesure dans le score
        // On doit trouver l'index de la mesure dans le score
        final measureIndex = score.measures.indexOf(measure);
        if (measureIndex >= 0) {
          allMeasureBounds[measureIndex] = measureLayout.boundingBox;
        }

        // Dessiner la signature rythmique pour la première mesure
        if (measureIndex == 0) {
          _drawTimeSignature(
            canvas,
            staffY,
            measureLayout.origin.dx,
            measure.timeSignature.numerator,
            measure.timeSignature.denominator,
          );
        }

        // Dessiner les notes (positions absolues déjà calculées)
        for (
          int noteIndex = 0;
          noteIndex < measureLayout.notes.length;
          noteIndex++
        ) {
          final note = measureLayout.notes[noteIndex];
          final String glyph = NoteEventHelper.getSymbol(note.noteModel);
          final Rect symbolBounds = GlyphPainter.drawGlyph(
            canvas,
            glyph,
            note.noteheadPosition,
            EngravingDefaults.symbolFontSize,
          );

          // Vérifier si la note est sélectionnée
          // L'ordre des notes dans measureLayout.notes correspond à l'ordre des events
          if (noteIndex < measure.events.length && measureIndex >= 0) {
            final reference = NoteSelectionReference(
              measureIndex: measureIndex,
              eventIndex: noteIndex,
            );
            if (selectedNotes.contains(reference)) {
              selectionBounds = _expandSelection(selectionBounds, symbolBounds);
            }
          }
        }

        // Dessiner les hampes (positions absolues déjà calculées)
        for (final note in measureLayout.notes) {
          if (note.noteModel.isRest) continue;
          BeamPainter.drawStem(
            canvas,
            note.stemX,
            note.stemTopY,
            note.stemBottomY,
            EngravingDefaults.stemThickness,
            Colors.black,
          );
        }

        // Dessiner les beams (positions absolues déjà calculées)
        for (final beam in measureLayout.beams) {
          BeamPainter.drawBeamSegment(
            canvas,
            beam,
            EngravingDefaults.beamThickness,
            Colors.black,
          );

          // Dessiner le numéro de tuplet si ce beam en a un
          if (beam.tupletNumber != null) {
            final double centerX = (beam.startX + beam.endX) / 2;

            // Position Y uniforme : toujours sous le beam le plus bas (niveau 0)
            // Calculer la position du beam niveau 0 pour ce groupe
            final double baseBeamY = staffY + EngravingDefaults.stemLength;
            final double tupletY =
                baseBeamY + EngravingDefaults.symbolFontSize * 0.5;

            _drawTupletNumber(
              canvas,
              beam.tupletNumber!,
              Offset(centerX, tupletY),
            );
          }
        }

        // Dessiner une barre à la fin de chaque mesure
        _drawBarlineSymbol(
          canvas,
          MusicSymbols.barlineSingle,
          measureLayout.barlineXStart - 1,
          staffY,
        );

        // Dessiner une barre à la fin de chaque système
        if (i == system.measures.length - 1) {
          _drawBarlineSymbol(
            canvas,
            MusicSymbols.barlineSingle,
            system.origin.dx + system.width,
            staffY,
          );
        }
      }
    }

    // Dessiner la sélection
    if (selectionBounds != null) {
      _drawSelectionBounds(canvas, selectionBounds);
    }

    // Dessiner le curseur
    final cursor = cursorPosition;
    if (cursor != null && pageLayoutResult.systems.isNotEmpty) {
      _drawCursor(canvas, size, cursor, allMeasureBounds);
    }
  }

  @override
  bool shouldRepaint(StaffPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.pageLayoutResult != pageLayoutResult ||
        oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.selectedNotes != selectedNotes;
  }

  void _drawBarlineSymbol(
    Canvas canvas,
    String symbol,
    double x,
    double centerY,
  ) {
    // Utiliser la même logique que l'ancien code pour centrer les barlines sur la ligne
    final double barLineHeight = AppConstants.barLineHeight; // 28.0
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: barLineHeight,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Calculer la position Y pour centrer la barre verticalement sur la ligne
    // Les barlines SMuFL ont leur baseline, il faut ajuster pour les centrer
    final double glyphHeightPx = barLineHeight;
    final double baselineDistance = textPainter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final double baselineY = centerY + glyphHeightPx / 2;
    final double offsetY = baselineY - baselineDistance;

    textPainter.paint(canvas, Offset(x, offsetY));
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
    final double fontSize = EngravingDefaults.symbolFontSize;
    final double timeSigSpacing =
        fontSize * 0.15; // Espacement SMuFL recommandé

    // 3. Créer les TextPainter pour chaque chiffre
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
    final double maxWidth = topGroupWidth > bottomGroupWidth
        ? topGroupWidth
        : bottomGroupWidth;

    // 6. Position X de base (juste avant la mesure)
    final double baseX = (startX - maxWidth - AppConstants.timeSignatureSpacing)
        .clamp(0.0, double.infinity);

    // 7. Positions Y selon SMuFL
    // Chiffre du haut : y = staffY - fontSize * 0.7
    // Chiffre du bas : y = staffY + fontSize * 0.7
    final double topY = centerY - fontSize * 0.7;
    final double bottomY = centerY + fontSize * 0.7;

    //8.Dessinerleschiffresduhaut(alignéscentrés)
    double currentX = baseX + (maxWidth - topGroupWidth) / 2;
    for (int i = 0; i < topPainters.length; i++) {
      final painter = topPainters[i];
      painter.paint(canvas, Offset(currentX, topY - painter.height / 2));
      currentX += painter.width;
      if (i < topPainters.length - 1) {
        currentX += timeSigSpacing;
      }
    }

    // 9. Dessiner les chiffres du bas (alignés centrés)
    currentX = baseX + (maxWidth - bottomGroupWidth) / 2;
    for (int i = 0; i < bottomPainters.length; i++) {
      final painter = bottomPainters[i];
      painter.paint(canvas, Offset(currentX, bottomY - painter.height / 2));
      currentX += painter.width;
      if (i < bottomPainters.length - 1) {
        currentX += timeSigSpacing;
      }
    }
  }

  /// Convertit un nombre en liste de chiffres.
  List<int> _numberToDigits(int number) {
    if (number == 0) return [0];
    final List<int> digits = [];
    int n = number;
    while (n > 0) {
      digits.insert(0, n % 10);
      n ~/= 10;
    }
    return digits;
  }

  void _drawSelectionBounds(Canvas canvas, Rect bounds) {
    final rrect = RRect.fromRectAndRadius(
      bounds.inflate(AppConstants.selectionPadding),
      const Radius.circular(AppConstants.selectionBorderRadius),
    );
    canvas.drawRRect(rrect, _selectionPaint);
  }

  Rect? _expandSelection(Rect? current, Rect next) {
    if (current == null) return next;
    return current.expandToInclude(next);
  }

  /// Dessine le curseur en tenant compte de plusieurs portées.
  ///
  /// Calcule la position X depuis cursor.positionInMeasure.
  void _drawCursor(
    Canvas canvas,
    Size size,
    StaffCursorPosition cursor,
    Map<int, Rect> measureBounds,
  ) {
    // Trouver la mesure correspondante
    final measureRect = measureBounds[cursor.measureIndex];
    if (measureRect == null) return;

    // Trouver le système qui contient cette mesure
    StaffLayoutResult? containingSystem;
    MeasureLayoutResult? containingMeasure;

    for (final system in pageLayoutResult.systems) {
      for (final measureLayout in system.measures) {
        if (measureLayout.measureModel == score.measures[cursor.measureIndex]) {
          containingSystem = system;
          containingMeasure = measureLayout;
          break;
        }
      }
      if (containingSystem != null) break;
    }
    print(cursor);

    if (containingSystem == null || containingMeasure == null) return;

    // Calculer la position X depuis cursor.positionInMeasure
    final measure = containingMeasure.measureModel;
    final double normalized = SelectionUtils.positionToNormalizedX(
      position: cursor.positionInMeasure,
      maxDuration: measure.maxDuration,
    );

    final double notesStartX =
        containingMeasure.barlineXStart + EngravingDefaults.spaceBeforeBarline;
    final double notesEndX =
        containingMeasure.barlineXEnd - EngravingDefaults.spaceBeforeBarline;
    final double notesSpan = notesEndX - notesStartX;
    final double cursorX = notesStartX + normalized * notesSpan;

    // Dessiner le curseur
    final double extent = EngravingDefaults.staffSpace * 2.5;
    final double top = (containingSystem.staffY - extent).clamp(
      0.0,
      size.height,
    );
    final double bottom = (containingSystem.staffY + extent).clamp(
      0.0,
      size.height,
    );

    canvas.drawLine(
      Offset(cursorX, top),
      Offset(cursorX, bottom),
      _cursorPaint,
    );
  }

  /// Dessine un numéro de tuplet à la position donnée en utilisant les glyphes SMuFL.
  void _drawTupletNumber(Canvas canvas, int number, Offset position) {
    // Utiliser le glyphe SMuFL spécifique pour les tuplets
    final String tupletGlyph = MusicSymbols.tupletDigit(number);

    final textPainter = TextPainter(
      text: TextSpan(
        text: tupletGlyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize:
              EngravingDefaults.symbolFontSize *
              0.8, // Taille appropriée pour les tuplets
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // Centrer le texte sur la position
    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }
}
