import '../model/duration_fraction.dart';
import '../model/note_event.dart';
import '../model/measure.dart';
import 'rest_filler.dart';

/// Utilitaires pour éditer une mesure avec une liste simple de notes.
class MeasureEditor {
  MeasureEditor._();

  /// Trouve l'index de l'événement pour une position temporelle donnée.
  /// 
  /// Retourne l'événement qui contient la position, ou le plus proche.
  /// 
  /// Retourne un tuple (index, splitEvent) où :
  /// - index : l'index de l'événement dans la liste (ou events.length si après tous les événements)
  /// - splitEvent : true si la position est au milieu de l'événement (nécessite subdivision)
  /// 
  /// [measure] : La mesure à analyser
  /// [position] : Position temporelle en DurationFraction depuis le début de la mesure
  static ({int index, bool splitEvent}) findEventIndex(
    Measure measure,
    DurationFraction position,
  ) {
    // Utiliser extractEventsWithPositions pour avoir les positions exactes
    final eventsWithPositions = extractEventsWithPositions(measure);
    
    // Chercher l'événement qui contient cette position
    for (int i = 0; i < eventsWithPositions.length; i++) {
      final entry = eventsWithPositions[i];
      final eventStart = entry.position;
      final eventEnd = eventStart.add(entry.event.duration);
      
      // Si on est dans cet événement
      if (position >= eventStart && position <= eventEnd) {
        final beforePosition = position.subtract(eventStart);
        final splitEvent = beforePosition > const DurationFraction(0, 1) && 
                          beforePosition < entry.event.duration;
        return (index: i, splitEvent: splitEvent);
      }
      
      // Si on est avant cet événement, c'est qu'on est entre le précédent et celui-ci
      if (position < eventStart) {
        // Retourner l'événement précédent si il existe, sinon celui-ci
        return (index: i > 0 ? i - 1 : i, splitEvent: false);
      }
    }
    
    // Après tous les événements
    return (index: measure.events.length, splitEvent: false);
  }

  /// Remplace l'événement à l'index donné par la note fournie.
  /// 
  /// Logique simple :
  /// - Si index >= events.length : insère à la fin (avec silences si nécessaire)
  /// - Sinon : remplace l'événement à l'index
  ///   - Si la note est plus petite : complète avec des silences
  ///   - Si la note est plus grande : supprime les événements suivants jusqu'à avoir assez de place
  /// 
  /// [measure] : La mesure à modifier
  /// [index] : Index dans la liste measure.events à remplacer (ou events.length pour insérer à la fin)
  /// [noteEvent] : L'événement musical qui remplace
  /// 
  /// Retourne une nouvelle mesure avec la note insérée.
  static Measure insertNote(
    Measure measure,
    int index,
    NoteEvent noteEvent,
  ) {
    print('insertNote: $measure, $index, $noteEvent');
    print('measure.events: ${measure.events}');
    final events = List<NoteEvent>.from(measure.events);
    final newEvents = <NoteEvent>[];
    
    // Ajouter tous les événements avant l'index
    for (int i = 0; i < index && i < events.length; i++) {
      newEvents.add(events[i]);
    }
    
    if (index >= events.length) {
      // Insérer à la fin : ajouter la note directement
      newEvents.add(noteEvent);
    } else {
      // Remplacer l'événement à l'index
      final targetEvent = events[index];
      final noteDuration = noteEvent.duration;
      final targetDuration = targetEvent.duration;
      
      newEvents.add(noteEvent);
      
      if (noteDuration < targetDuration) {
        // Note plus petite : compléter avec des silences
        final remaining = targetDuration.subtract(noteDuration);
        if (remaining.numerator > 0) {
          final rests = RestFiller.fillSpaceWithRests(remaining);
          newEvents.addAll(rests);
        }
        
        // Ajouter les événements après
        for (int i = index + 1; i < events.length; i++) {
          newEvents.add(events[i]);
        }
      } else if (noteDuration > targetDuration) {
        // Note plus grande : supprimer les événements suivants jusqu'à avoir assez de place
        DurationFraction usedDuration = targetDuration;
        int nextIndex = index + 1;
        
        while (nextIndex < events.length && usedDuration < noteDuration) {
          usedDuration = usedDuration.add(events[nextIndex].duration);
          nextIndex++;
        }
        
        // Si on a encore besoin de place, on remplit avec des silences
        if (usedDuration < noteDuration) {
          final missing = noteDuration.subtract(usedDuration);
          if (missing.numerator > 0) {
            final rests = RestFiller.fillSpaceWithRests(missing);
            newEvents.addAll(rests);
          }
        }
        
        // Ajouter les événements restants après
        for (int i = nextIndex; i < events.length; i++) {
          newEvents.add(events[i]);
        }
      } else {
        // Durée égale : juste remplacer, ajouter les événements après
        for (int i = index + 1; i < events.length; i++) {
          newEvents.add(events[i]);
        }
      }
    }
    
    // Remplir avec des silences pour compléter la mesure
    final filledEvents = _fillRests(newEvents, measure.maxDuration);
    
    return measure.copyWith(events: filledEvents);
  }

  /// Remplit les espaces vides avec des silences.
  static List<NoteEvent> _fillRests(
    List<NoteEvent> events,
    DurationFraction maxDuration,
  ) {
    final totalDuration = events.fold<DurationFraction>(
      const DurationFraction(0, 1),
      (sum, event) => sum.add(event.duration),
    );

    final remaining = maxDuration.subtract(totalDuration);
    if (remaining.numerator > 0) {
      final rests = RestFiller.fillSpaceWithRests(remaining);
      return [...events, ...rests];
    }

    return events;
  }

  /// Extrait les événements avec leurs positions.
  static List<({DurationFraction position, NoteEvent event})> extractEventsWithPositions(
    Measure measure,
  ) {
    final result = <({DurationFraction position, NoteEvent event})>[];
    DurationFraction currentPosition = const DurationFraction(0, 1);

    for (final event in measure.events) {
      result.add((position: currentPosition, event: event));
      currentPosition = currentPosition.add(event.duration);
    }

    return result;
  }
}

