import 'package:flutter/foundation.dart';
import 'package:snare_notation/utils/music_symbols.dart';

import 'accent.dart';
import 'duration_fraction.dart';
import 'ornament.dart';
import 'tuplet_info.dart';

/// Événement rythmique dans une mesure (note ou silence).
///
/// Peut contenir des informations sur les tuplets, ornements et accents.
@immutable
class NoteEvent {
  const NoteEvent({
    required this.actualDuration,
    required this.writenDuration,
    this.tuplet,
    this.ornament,
    this.accent,
    this.isRest = false,
    this.isAboveLine = false,
  });

  /// Durée de l'événement.
  final DurationFraction actualDuration;

  /// Durée écrite de l'événement.
  final NoteDuration writenDuration;

  /// Information sur le tuplet si applicable.
  final TupletInfo? tuplet;

  /// Ornement si applicable.
  final Ornament? ornament;

  /// Accent si applicable.
  final Accent? accent;

  /// Indique si c'est un silence (true) ou une note (false).
  final bool isRest;

  /// Indique si la note doit être placée au-dessus de la ligne centrale.
  /// Ignoré pour les silences.
  final bool isAboveLine;

  NoteEvent copyWith({
    DurationFraction? duration,
    NoteDuration? writenDuration,
    TupletInfo? tuplet,
    Ornament? ornament,
    Accent? accent,
    bool? isRest,
    bool? isAboveLine,
  }) {
    return NoteEvent(
      actualDuration: duration ?? this.actualDuration,
      writenDuration: writenDuration ?? this.writenDuration,
      tuplet: tuplet ?? this.tuplet,
      ornament: ornament ?? this.ornament,
      accent: accent ?? this.accent,
      isRest: isRest ?? this.isRest,
      isAboveLine: isAboveLine ?? this.isAboveLine,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteEvent) return false;
    return actualDuration == other.actualDuration &&
        tuplet == other.tuplet &&
        ornament == other.ornament &&
        accent == other.accent &&
        isRest == other.isRest &&
        isAboveLine == other.isAboveLine;
  }

  @override
  int get hashCode {
    return Object.hash(actualDuration, tuplet, ornament, accent, isRest, isAboveLine);
  }

  @override
  String toString() {
    final String base = isRest ? 'Rest' : 'Note';
    final String dur = actualDuration.toString();
    final String wdur = writenDuration.name;
    final String tup = tuplet != null ? ' (${tuplet.toString()})' : '';
    final String orn = ornament != null ? ' ${ornament.toString()}' : '';
    final String acc = accent != null ? ' ${accent.toString()}' : '';
    final String pos = isRest ? '' : (isAboveLine ? ' ↑' : ' ↓');
    return '$base($dur$wdur$tup$orn$acc$pos)';
  }

  Map<String, dynamic> toJson() => {
        'duration': actualDuration.toJson(),
        'writenDuration': writenDuration.name,
        if (tuplet != null) 'tuplet': tuplet!.toJson(),
        if (ornament != null) 'ornament': ornament!.toJson(),
        if (accent != null) 'accent': accent!.toJson(),
        'isRest': isRest,
        'isAboveLine': isAboveLine,
      };

  factory NoteEvent.fromJson(Map<String, dynamic> json) {
    return NoteEvent(
      actualDuration: DurationFraction.fromJson(
        json['duration'] as Map<String, dynamic>,
      ),
      writenDuration: NoteDuration.values.byName(
        json['writenDuration'] as String
      ),
      tuplet: json['tuplet'] != null
          ? TupletInfo.fromJson(json['tuplet'] as Map<String, dynamic>)
          : null,
      ornament: Ornament.fromJson(json['ornament'] as String?),
      accent: Accent.fromJson(json['accent'] as String?),
      isRest: json['isRest'] as bool? ?? false,
      isAboveLine: json['isAboveLine'] as bool? ?? false,
    );
  }
}

