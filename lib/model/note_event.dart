import 'package:flutter/foundation.dart';

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
    required this.duration,
    this.tuplet,
    this.ornament,
    this.accent,
    this.isRest = false,
  });

  /// Durée de l'événement.
  final DurationFraction duration;

  /// Information sur le tuplet si applicable.
  final TupletInfo? tuplet;

  /// Ornement si applicable.
  final Ornament? ornament;

  /// Accent si applicable.
  final Accent? accent;

  /// Indique si c'est un silence (true) ou une note (false).
  final bool isRest;

  NoteEvent copyWith({
    DurationFraction? duration,
    TupletInfo? tuplet,
    Ornament? ornament,
    Accent? accent,
    bool? isRest,
  }) {
    return NoteEvent(
      duration: duration ?? this.duration,
      tuplet: tuplet ?? this.tuplet,
      ornament: ornament ?? this.ornament,
      accent: accent ?? this.accent,
      isRest: isRest ?? this.isRest,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteEvent) return false;
    return duration == other.duration &&
        tuplet == other.tuplet &&
        ornament == other.ornament &&
        accent == other.accent &&
        isRest == other.isRest;
  }

  @override
  int get hashCode {
    return Object.hash(duration, tuplet, ornament, accent, isRest);
  }

  @override
  String toString() {
    final String base = isRest ? 'Rest' : 'Note';
    final String dur = duration.toString();
    final String tup = tuplet != null ? ' (${tuplet.toString()})' : '';
    final String orn = ornament != null ? ' ${ornament.toString()}' : '';
    final String acc = accent != null ? ' ${accent.toString()}' : '';
    return '$base($dur$tup$orn$acc)';
  }

  Map<String, dynamic> toJson() => {
        'duration': duration.toJson(),
        if (tuplet != null) 'tuplet': tuplet!.toJson(),
        if (ornament != null) 'ornament': ornament!.toJson(),
        if (accent != null) 'accent': accent!.toJson(),
        'isRest': isRest,
      };

  factory NoteEvent.fromJson(Map<String, dynamic> json) {
    return NoteEvent(
      duration: DurationFraction.fromJson(
        json['duration'] as Map<String, dynamic>,
      ),
      tuplet: json['tuplet'] != null
          ? TupletInfo.fromJson(json['tuplet'] as Map<String, dynamic>)
          : null,
      ornament: Ornament.fromJson(json['ornament'] as String?),
      accent: Accent.fromJson(json['accent'] as String?),
      isRest: json['isRest'] as bool? ?? false,
    );
  }
}

