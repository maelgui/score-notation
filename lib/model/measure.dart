import 'package:flutter/foundation.dart';

import 'duration_fraction.dart';
import 'note_event.dart';
import 'time_signature.dart';

/// Mesure musicale avec une liste simple de NoteEvent.
///
/// La mesure contient une liste de NoteEvent dans l'ordre chronologique.
/// La durée totale doit correspondre à la signature rythmique.
@immutable
class Measure {
  const Measure({
    required this.timeSignature,
    required this.number,
    this.events = const [],
  });

  /// Signature rythmique de cette mesure.
  final TimeSignature timeSignature;

  /// Liste des événements musicaux (notes et silences) dans l'ordre chronologique.
  final List<NoteEvent> events;

  /// Numéro de la mesure (1-indexed, optionnel pour compatibilité).
  final int number;

  /// Durée maximale de la mesure selon la signature rythmique.
  DurationFraction get maxDuration {
    // Pour 4/4 : 4 temps de 1/4 = 4/4 = 1/1 (une ronde)
    return DurationFraction(
      timeSignature.numerator,
      timeSignature.denominator,
    );
  }

  /// Durée totale actuelle de la mesure.
  DurationFraction get totalDuration {
    return events.fold<DurationFraction>(
      const DurationFraction(0, 1),
      (sum, event) => sum.add(event.actualDuration),
    );
  }

  /// Vérifie si la mesure est complète (durée totale = durée maximale).
  bool get isComplete {
    return totalDuration == maxDuration;
  }

  Measure copyWith({
    TimeSignature? timeSignature,
    List<NoteEvent>? events,
    int? number,
  }) {
    return Measure(
      timeSignature: timeSignature ?? this.timeSignature,
      events: events ?? this.events,
      number: number ?? this.number,
    );
  }

  /// Crée une mesure vide remplie de silences.
  factory Measure.empty(TimeSignature timeSignature, int number) {
    // Créer des silences pour chaque temps
    final restDuration = DurationFraction(1, timeSignature.denominator);
    // NoteDuration from restDuration
    final writenDuration = restDuration.toNoteDuration();
    final events = List.generate(
      timeSignature.numerator,
      (_) => NoteEvent(
        actualDuration: restDuration,
        writenDuration: writenDuration!,
        isRest: true,
      ),
    );
    return Measure(timeSignature: timeSignature, events: events, number: number);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Measure) return false;
    if (timeSignature != other.timeSignature) return false;
    if (number != other.number) return false;
    if (events.length != other.events.length) return false;
    for (int i = 0; i < events.length; i++) {
      if (events[i] != other.events[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(timeSignature, number, events.length);
  }

  @override
  String toString() {
    return 'Measure(#$number $timeSignature, ${events.length} events, duration: $totalDuration/$maxDuration)';
  }

  Map<String, dynamic> toJson() => {
        'timeSignature': timeSignature.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
        'number': number,
      };

  factory Measure.fromJson(Map<String, dynamic> json) {
    return Measure(
      timeSignature: TimeSignature.fromJson(
        json['timeSignature'] as Map<String, dynamic>,
      ),
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => NoteEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      number: json['number'] as int,
    );
  }
}


